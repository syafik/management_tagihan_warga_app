class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment, only: [:show]
  skip_before_action :action_allowed

  def new
    # Get address based on params or fallback to first address
    if params[:address_id].present?
      # Find specific address that belongs to current user
      @user_address = current_user.user_addresses.includes(:address).find_by(address_id: params[:address_id])

      unless @user_address
        redirect_to root_path, alert: 'Alamat tidak ditemukan atau tidak dapat diakses' and return
      end
    else
      # Fallback to first address if user has only one
      @user_address = current_user.user_addresses.includes(:address).first
      redirect_to root_path, alert: 'Anda belum terdaftar di alamat manapun' and return unless @user_address
    end

    @address = @user_address.address

    # Get unpaid months - compare expected vs paid contributions
    @unpaid_months = calculate_unpaid_months(@address)
  end

  def create
    # Get address based on params (from form hidden field)
    if params[:address_id].present?
      @user_address = current_user.user_addresses.includes(:address).find_by(address_id: params[:address_id])

      unless @user_address
        redirect_to root_path, alert: 'Alamat tidak ditemukan atau tidak dapat diakses' and return
      end
    else
      # Fallback to first address
      @user_address = current_user.user_addresses.includes(:address).first
      redirect_to root_path, alert: 'Anda belum terdaftar di alamat manapun' and return unless @user_address
    end

    @address = @user_address.address

    # Get selected month keys (format: "2025-1", "2025-2", etc.)
    selected_months = params[:selected_months] || []

    if selected_months.empty?
      redirect_to new_payment_path(address_id: @address.id), alert: 'Pilih minimal 1 bulan untuk dibayar'
      return
    end

    # Parse selected months
    @months_to_pay = selected_months.map do |month_key|
      if month_key.start_with?('arrears-')
        # Handle old arrears: format "arrears-1", "arrears-2", etc.
        arrears_index = month_key.split('-').last.to_i
        arrears_rate = get_contribution_amount(@address, Date.current.year, 1)

        # Each arrears is treated as individual payment
        {
          type: 'arrears',
          arrears_index: arrears_index, # Track which arrears (1, 2, 3, etc.)
          amount: arrears_rate
        }
      else
        # Regular month: format "2025-1"
        year, month = month_key.split('-').map(&:to_i)
        {
          type: 'regular',
          year: year,
          month: month,
          amount: get_contribution_amount(@address, year, month)
        }
      end
    end

    # Calculate contribution total
    contribution_total = @months_to_pay.sum { |m| m[:amount] }

    # Calculate fee and total with fee
    tripay_service = TripayService.new
    payment_breakdown = tripay_service.calculate_total_with_fee(contribution_total)

    # Build month list for order description
    month_names = UserContribution::MONTHNAMES.invert
    months_list = @months_to_pay.map do |m|
      if m[:type] == 'arrears'
        "Tunggakan #{m[:arrears_index]}"
      else
        "#{month_names[m[:month]]} #{m[:year]}"
      end
    end

    begin
      # Create payment via Tripay with total including fee
      tripay_data = tripay_service.create_transaction(
        user: current_user,
        address: @address,
        amount: payment_breakdown[:total], # Total sudah include fee
        months: months_list
      )

      # Save payment record
      # IMPORTANT: We save merchant_ref as reference (for callback lookup)
      # Tripay reference is saved in tripay_response
      payment = Payment.create!(
        reference: tripay_data['merchant_ref'], # OUR reference for callback
        user: current_user,
        address: @address,
        amount: payment_breakdown[:total], # Total yang dibayar (sudah include fee)
        status: 'UNPAID',
        payment_method: 'QRIS',
        payment_channel: tripay_data['payment_method'],
        checkout_url: tripay_data['checkout_url'],
        qr_url: tripay_data['qr_url'],
        expired_at: Time.at(tripay_data['expired_time']),
        tripay_response: tripay_data.merge({
          'contribution_amount' => payment_breakdown[:contribution],
          'fee_amount' => payment_breakdown[:fee],
          'total_amount' => payment_breakdown[:total],
          'tripay_reference' => tripay_data['reference'] # Tripay's reference
        }),
        notes: "#{months_list.join(', ')} - #{@months_to_pay.to_json}"
      )

      redirect_to payment_path(payment.reference)
    rescue TripayService::TripayError => e
      redirect_to new_payment_path(address_id: @address.id), alert: "Gagal membuat pembayaran: #{e.message}"
    rescue => e
      Rails.logger.error "Payment creation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to new_payment_path(address_id: @address.id), alert: 'Terjadi kesalahan saat membuat pembayaran'
    end
  end

  def show
    @time_remaining = @payment.time_remaining

    # Auto-refresh status if payment is still pending
    if @payment.pending? && !@payment.expired?
      begin
        tripay_service = TripayService.new
        # Use Tripay reference to get transaction detail
        tripay_reference = @payment.tripay_response['tripay_reference'] || @payment.tripay_response['reference']
        tripay_data = tripay_service.get_transaction_detail(tripay_reference)

        # Update payment status from Tripay
        if tripay_data['status'] == 'PAID' && @payment.pending?
          @payment.mark_as_paid!(Time.at(tripay_data['paid_at']))
          process_payment_success(@payment)
        elsif tripay_data['status'] == 'EXPIRED'
          @payment.mark_as_expired!
        elsif tripay_data['status'] == 'FAILED'
          @payment.mark_as_failed!
        end
      rescue TripayService::TripayError => e
        Rails.logger.error "Failed to refresh payment status: #{e.message}"
      end
    end
  end

  private

  def set_payment
    # Route uses :reference parameter, not :id
    reference = params[:reference] || params[:id]
    @payment = current_user.payments.find_by(reference: reference)

    unless @payment
      redirect_to user_contributions_path, alert: 'Pembayaran tidak ditemukan'
      return
    end
  end

  def process_payment_success(payment)
    # IMPORTANT: This method is idempotent (safe to call multiple times)
    # It will be called from both:
    # 1. Show action (when checking payment status)
    # 2. Tripay callback (when receiving webhook)

    # Wrap entire process in transaction with pessimistic locking to prevent race conditions
    Payment.transaction do
      # Use pessimistic locking to prevent race conditions
      # This ensures only one thread can process the payment at a time
      payment = Payment.lock.find(payment.id)

      # Check if already processed (avoid double processing)
      if payment.tripay_response&.dig('processed_at').present?
        Rails.logger.info "Payment #{payment.reference} already processed at #{payment.tripay_response['processed_at']}, skipping"
        return
      end

      # Parse months from payment notes
      return unless payment.notes.present?

      # Extract JSON from notes (format: "Month1, Month2 - [{...}]")
      json_match = payment.notes.match(/\[.*\]/)
      return unless json_match

      months_data = JSON.parse(json_match[0])

      # Create UserContribution records for each paid month
      admin_user = User.find_by(role: 'admin') || User.first
      total_months_paid = 0
      arrears_paid_count = 0
      created_contribution_ids = []
      user_contributions_created = []
      total_contribution_amount = 0

      months_data.each do |month_data|
        if month_data['type'] == 'arrears'
          # Handle individual arrears payment - each arrears reduces address.arrears by 1
          arrears_index = month_data['arrears_index']
          arrears_paid_count += 1
          total_contribution_amount += month_data['amount'].to_i

          # NOTE: We don't create UserContribution for arrears
          # We only reduce the arrears counter
          Rails.logger.info "Processing arrears payment ##{arrears_index} for address #{payment.address.block_address}"

          total_months_paid += 1
        else
          # Regular month payment - create UserContribution (only if not exists)
          existing = UserContribution.find_by(
            address: payment.address,
            year: month_data['year'],
            month: month_data['month']
          )

          amount = month_data['amount'].to_i

          if existing
            Rails.logger.info "UserContribution already exists for #{month_data['year']}-#{month_data['month']}, skipping"
            created_contribution_ids << existing.id
          else
            uc = UserContribution.create!(
              address: payment.address,
              year: month_data['year'],
              month: month_data['month'],
              contribution: amount,
              expected_contribution: amount,
              pay_at: payment.paid_at,
              receiver_id: admin_user.id,
              payment_type: UserContribution::PAYMENT_TYPES['QRIS'],
              blok: payment.address.block_address.gsub(/[^A-Za-z]/, '').upcase,
              description: "Pembayaran via QRIS - #{payment.reference}"
            )
            created_contribution_ids << uc.id
            user_contributions_created << uc
            total_contribution_amount += amount
            Rails.logger.info "Created UserContribution for #{month_data['year']}-#{month_data['month']}"
          end
          total_months_paid += 1
        end
      end

      # Update address arrears count (reduce by number of arrears paid)
      if arrears_paid_count > 0
        new_arrears = [payment.address.arrears.to_i - arrears_paid_count, 0].max
        payment.address.update(arrears: new_arrears)
        Rails.logger.info "Updated address #{payment.address.block_address} arrears: #{payment.address.arrears} -> #{new_arrears}"
      end

      # Create single grouped cash transaction for all contributions
      if total_contribution_amount > 0
        description_parts = []
        description_parts << "Tunggakan Lama (#{arrears_paid_count} bulan)" if arrears_paid_count > 0

        if user_contributions_created.any?
          months_text = user_contributions_created.map { |uc| UserContribution::MONTHNAMES.invert[uc.month] }.join(', ')
          description_parts << "#{user_contributions_created.count} bulan (#{months_text})"
        end

        first_contribution = user_contributions_created.first
        transaction_month = first_contribution&.month || payment.paid_at.month
        transaction_year = first_contribution&.year || payment.paid_at.year

        CashTransaction.create(
          month: transaction_month,
          year: transaction_year,
          transaction_date: payment.paid_at,
          transaction_type: CashTransaction::TYPE['DEBIT'],
          transaction_group: CashTransaction::GROUP['IURAN WARGA'],
          description: "#{payment.address.block_address} pembayaran iuran via QRIS (#{description_parts.join(' + ')})",
          total: total_contribution_amount,
          pic_id: admin_user.id
        )
        Rails.logger.info "Created CashTransaction for payment #{payment.reference} with total #{total_contribution_amount}"
      end

      # Mark as processed to prevent double processing
      payment.update!(
        tripay_response: payment.tripay_response.merge({
          'processed_at' => Time.current.to_s,
          'processed_months' => total_months_paid,
          'processed_arrears' => arrears_paid_count
        })
      )

      Rails.logger.info "Processed #{total_months_paid} contributions (#{arrears_paid_count} arrears) for payment #{payment.reference}"

      # Create notification (outside transaction to avoid blocking)
      create_payment_notification(payment, created_contribution_ids, arrears_paid_count, total_contribution_amount)
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse payment months: #{e.message}"
  end

  def create_payment_notification(payment, contribution_ids, arrears_count, total_amount)
    # Send WhatsApp notification with payment details including arrears
    if contribution_ids.any? || arrears_count > 0
      SendPaymentNotificationJob.perform_later(
        contribution_ids,
        payment.id,
        arrears_count,
        total_amount
      )
    end

    Rails.logger.info "Created notifications for payment #{payment.reference}"
  rescue => e
    Rails.logger.error "Failed to create notification: #{e.message}"
  end

  # Calculate which months are unpaid for an address
  def calculate_unpaid_months(address)
    current_date = Date.current
    current_year = current_date.year
    next_year = current_year + 1

    # Get all paid contributions for this address in current and next year
    paid_contributions = UserContribution.where(address_id: address.id)
                                        .pluck(:year, :month)
                                        .map { |y, m| "#{y}-#{m}" }
                                        .to_set

    unpaid = []

    # 1. Add arrears count from address model (tunggakan lama) - one box per month
    if address.arrears.present? && address.arrears > 0
      # Get contribution rate for arrears (use current year rate for simplicity)
      arrears_rate = get_contribution_amount(address, current_year, 1)

      # Create individual boxes for each arrears month
      (1..address.arrears).each do |arrears_index|
        unpaid << {
          year: nil, # Mark as arrears, not specific year
          month: nil,
          month_name: "Tunggakan #{arrears_index}",
          amount: arrears_rate,
          arrears_index: arrears_index, # Track which arrears month this is
          is_arrears: true,
          is_old_arrears: true,
          is_next_year: false
        }
      end
    end

    # 2. Calculate unpaid months for current year
    # Include ALL months from January to December
    (1..12).each do |month|
      month_key = "#{current_year}-#{month}"

      unless paid_contributions.include?(month_key)
        contribution_amount = get_contribution_amount(address, current_year, month)

        # Determine if this month is due (past/current) or future
        month_date = Date.new(current_year, month, 1)
        is_due = month_date < current_date.beginning_of_month
        is_current_month = month == current_date.month
        is_future = month_date > current_date.beginning_of_month

        unpaid << {
          year: current_year,
          month: month,
          month_name: UserContribution::MONTHNAMES.invert[month],
          amount: contribution_amount,
          is_arrears: is_due, # Past months are arrears
          is_current_month: is_current_month,
          is_future: is_future,
          is_old_arrears: false,
          is_next_year: false
        }
      end
    end

    # 3. If current month is October or later (month >= 10), show next year's months
    next_year_months = []
    if current_date.month >= 10
      (1..12).each do |month|
        month_key = "#{next_year}-#{month}"

        unless paid_contributions.include?(month_key)
          contribution_amount = get_contribution_amount(address, next_year, month)

          next_year_months << {
            year: next_year,
            month: month,
            month_name: UserContribution::MONTHNAMES.invert[month],
            amount: contribution_amount,
            is_arrears: false,
            is_current_month: false,
            is_future: true,
            is_old_arrears: false,
            is_next_year: true
          }
        end
      end
    end

    # Group by category: arrears, current year unpaid, current year future, and next year
    current_year_unpaid = unpaid.reject { |m| m[:is_old_arrears] }

    {
      arrears: unpaid.select { |m| m[:is_old_arrears] },
      current_year_past: current_year_unpaid.select { |m| m[:is_arrears] },
      current_year_future: current_year_unpaid.select { |m| m[:is_future] || m[:is_current_month] },
      next_year: next_year_months
    }
  end

  # Get contribution amount for a specific month/year
  def get_contribution_amount(address, year, month)
    # Use Address model's expected_contribution_for method
    # This already handles hierarchy: address-specific > block-specific > global
    address.expected_contribution_for(month, year) || 190000
  end
end
