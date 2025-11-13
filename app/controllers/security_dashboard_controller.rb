# frozen_string_literal: true

class SecurityDashboardController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authenticate_user!
  before_action :ensure_security_role

  def index
    @year_selected = (params[:year] || Date.current.year).to_i
    @current_month = Date.current.month
    @current_year = Date.current.year
    @search_term = params[:search]
    @selected_block = params[:block]

    # Get blocks that this security has access to
    @accessible_blocks = get_accessible_blocks

    # If no block selected, default to first accessible block
    @selected_block = @accessible_blocks.first if @selected_block.blank? && @accessible_blocks.any?

    # Get addresses based on security's pic_blok
    addresses = get_security_addresses

    # Filter by selected block
    if @selected_block.present?
      addresses = addresses.where("block_address ~ ?", "^#{@selected_block}")
    end

    # Apply search filter
    if @search_term.present?
      addresses = addresses.where(
        "UPPER(block_address) LIKE UPPER(?) OR EXISTS (
          SELECT 1 FROM user_addresses ua
          INNER JOIN users u ON ua.user_id = u.id
          WHERE ua.address_id = addresses.id
          AND ua.kk = true
          AND UPPER(u.name) LIKE UPPER(?)
        )",
        "%#{@search_term}%", "%#{@search_term}%"
      )
    end

    # Order by block letter first, then by number
    addresses = addresses.order(
      Arel.sql("SUBSTRING(block_address FROM '^[A-Za-z]+'), CAST(SUBSTRING(block_address FROM '[0-9]+') AS INTEGER)")
    )

    # Preload associations for performance
    addresses = addresses.includes(:head_of_family, :user_contributions)

    # Calculate unpaid months for each address
    @addresses_with_unpaid = addresses.map do |address|
      unpaid_count = calculate_unpaid_months(address, @current_year, @current_month)
      arrears_months = address.arrears || 0
      arrears_amount = arrears_months * address.current_contribution_rate

      {
        address: address,
        unpaid_months: unpaid_count,
        arrears: arrears_months,
        arrears_amount: arrears_amount,
        total_unpaid_amount: (unpaid_count * address.current_contribution_rate) + arrears_amount
      }
    end
  end

  def payment_page
    @address = Address.find(params[:address_id])

    # Verify security has access to this address
    unless can_access_address?(@address)
      redirect_to security_dashboard_index_path, alert: 'Akses ditolak'
      return
    end

    @current_year = Date.current.year
    @current_month = Date.current.month

    # Get arrears (tunggakan lama) - stored as number of months, not rupiah
    @arrears_months = @address.arrears || 0
    @arrears_amount = @arrears_months * @address.current_contribution_rate

    # Get unpaid months (from starting_year to now)
    @unpaid_months = get_unpaid_months_list(@address, @current_year, @current_month)

    # Get future months (next 6 months)
    @future_months = get_future_months_list(@address, @current_year, @current_month, 6)

    # Calculate totals
    @total_arrears = @arrears_amount
    @total_unpaid = @unpaid_months.sum { |m| @address.expected_contribution_for(m[:month], m[:year]) }
    @total_future = @future_months.sum { |m| m[:contribution_rate] }
    @grand_total = @total_arrears + @total_unpaid
  end

  def address_detail
    address = Address.find(params[:id])

    # Verify security has access to this address
    unless can_access_address?(address)
      render json: { success: false, error: 'Akses ditolak' }, status: :forbidden
      return
    end

    current_year = Date.current.year
    current_month = Date.current.month
    include_future = params[:include_future] == 'true'

    # Get all unpaid months from starting_year to now
    unpaid_months = get_unpaid_months_list(address, current_year, current_month)

    # Build unpaid months data
    unpaid_data = unpaid_months.map do |month_data|
      year = month_data[:year]
      month = month_data[:month]
      contribution_rate = address.expected_contribution_for(month, year)

      {
        month: month,
        month_text: UserContribution::MONTHNAMES.invert[month],
        year: year,
        contribution_rate: contribution_rate,
        formatted_rate: format_currency(contribution_rate),
        is_paid: false,
        is_future: false,
        paid_amount: nil,
        pay_date: nil,
        payment_id: nil,
        receiver_name: nil
      }
    end

    # Add future months if requested (next 12 months from current month)
    future_data = []
    if include_future
      future_data = get_future_months_list(address, current_year, current_month, 12)
    end

    # Combine unpaid and future months
    all_months_data = unpaid_data + future_data

    # Calculate total unpaid amount (only past/current, not future)
    total_unpaid = unpaid_data.sum { |m| m[:contribution_rate] }

    render json: {
      success: true,
      address: {
        id: address.id,
        block_address: address.block_address&.upcase,
        head_of_family_name: address.head_of_family&.name&.upcase || 'Tidak ada'
      },
      months: all_months_data,
      total_unpaid: total_unpaid,
      formatted_total_unpaid: format_currency(total_unpaid),
      unpaid_count: unpaid_data.count,
      future_count: future_data.count
    }
  end

  def rekap_pembayaran
    @year_selected = (params[:year] || Date.current.year).to_i
    @month_selected = (params[:month] || Date.current.month).to_i

    # Get blocks that this security has access to
    @accessible_blocks = get_accessible_blocks

    # Default to first block if not specified (untuk performance)
    @selected_block = params[:block].presence || @accessible_blocks.first

    # Get all payments received by current security user based on pay_at date (tanggal terima pembayaran)
    start_date = Date.new(@year_selected, @month_selected, 1)
    end_date = start_date.end_of_month

    # Get ALL payments for totals (from all blocks)
    all_payments_for_totals = UserContribution.where(receiver_id: current_user.id)
                                              .where(pay_at: start_date..end_date)

    # Get total expenses by current security user for this month
    total_expenses = CashTransaction.where(pic_id: current_user.id)
                                    .where(transaction_type: CashTransaction::TYPE['KREDIT'])
                                    .where(transaction_group: CashTransaction::GROUP['LAIN-LAIN'])
                                    .where(transaction_date: start_date..end_date)
                                    .sum(:total)

    # Calculate GRAND TOTALS from all blocks
    @total_cash = all_payments_for_totals.where(payment_type: 1).sum(:contribution)
    @total_transfer = all_payments_for_totals.where(payment_type: 2).sum(:contribution)
    @grand_total = @total_cash - total_expenses
    @total_expenses = total_expenses
    @total_count = all_payments_for_totals.count

    # Get payments for selected block only (for display)
    selected_block_payments = UserContribution.where(receiver_id: current_user.id)
                                              .where(pay_at: start_date..end_date)
                                              .where(blok: @selected_block)
                                              .includes(:address)
                                              .order(pay_at: :desc)

    # Group payments by block
    @payments_by_block = selected_block_payments.group_by(&:blok)

    # Calculate per-block totals (only for selected block)
    @block_totals = {}
    block_payments = selected_block_payments.to_a
    @block_totals[@selected_block] = {
      cash: block_payments.select { |p| p.payment_type == 1 }.sum(&:contribution),
      transfer: block_payments.select { |p| p.payment_type == 2 }.sum(&:contribution),
      total: block_payments.sum(&:contribution),
      count: block_payments.count
    }
  end

  def new_expense
    @year = (params[:year] || Date.current.year).to_i
    @month = (params[:month] || Date.current.month).to_i

    # Get expenses recorded by current security user
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    @expenses = CashTransaction.where(pic_id: current_user.id)
                               .where(transaction_type: CashTransaction::TYPE['KREDIT'])
                               .where(transaction_group: CashTransaction::GROUP['LAIN-LAIN'])
                               .where(transaction_date: start_date..end_date)
                               .order(transaction_date: :desc)

    # Calculate total
    @total_expenses = @expenses.sum(:total)
    @expense_count = @expenses.count
  end

  def create_expense
    unless params[:total].present? && params[:description].present?
      redirect_to new_expense_security_dashboard_index_path, alert: 'Total dan deskripsi harus diisi'
      return
    end

    total = params[:total].to_f
    description = params[:description]
    category = params[:category] || 'LAIN-LAIN'
    transaction_date = params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.current

    cash_transaction = CashTransaction.new(
      month: transaction_date.month,
      year: transaction_date.year,
      transaction_date: transaction_date,
      transaction_type: CashTransaction::TYPE['KREDIT'],
      transaction_group: CashTransaction::GROUP[category],
      description: description,
      total: total,
      pic_id: current_user.id
    )

    if cash_transaction.save
      redirect_to new_expense_security_dashboard_index_path, notice: 'Pengeluaran berhasil dicatat!'
    else
      redirect_to new_expense_security_dashboard_index_path, alert: 'Gagal mencatat pengeluaran'
    end
  end

  def confirm_payment
    @address = Address.find_by(id: params[:address_id])

    unless @address && can_access_address?(@address)
      redirect_to security_dashboard_index_path, alert: 'Akses ditolak'
      return
    end

    @payment_type = params[:payment_type]&.to_i || 1
    @pay_arrears = params[:pay_arrears] == '1'
    @unpaid_months = params[:unpaid_months] || []
    @future_months = params[:future_months] || []

    if !@pay_arrears && @unpaid_months.empty? && @future_months.empty?
      redirect_to payment_security_dashboard_index_path(address_id: @address.id),
                  alert: 'Pilih minimal 1 item pembayaran'
      return
    end

    # Calculate total and prepare display data
    @total_amount = 0
    @selected_items = []

    # Process arrears
    if @pay_arrears && @address.arrears.to_i > 0
      arrears_amount = @address.arrears * @address.current_contribution_rate
      @total_amount += arrears_amount
      @selected_items << {
        category: 'Tunggakan Lama',
        description: "#{@address.arrears} bulan tunggakan",
        amount: arrears_amount
      }
    end

    # Process unpaid months
    @unpaid_months.each do |month_year|
      month, year = month_year.split(',').map(&:to_i)
      expected_contribution = @address.expected_contribution_for(month, year)
      month_text = UserContribution::MONTHNAMES.invert[month]

      @selected_items << {
        category: 'Belum Bayar',
        description: "#{month_text} #{year}",
        amount: expected_contribution
      }
      @total_amount += expected_contribution
    end

    # Process future months
    @future_months.each do |month_year|
      month, year = month_year.split(',').map(&:to_i)
      expected_contribution = @address.expected_contribution_for(month, year)
      month_text = UserContribution::MONTHNAMES.invert[month]

      @selected_items << {
        category: 'Bayar Bulan Lain',
        description: "#{month_text} #{year}",
        amount: expected_contribution
      }
      @total_amount += expected_contribution
    end

    @current_date = Date.current.strftime('%d %B %Y')
  end

  def create_payment
    address = Address.find_by(id: params[:address_id])

    unless address && can_access_address?(address)
      redirect_to security_dashboard_index_path, alert: 'Akses ditolak'
      return
    end

    payment_type = params[:payment_type]&.to_i || 1
    pay_arrears = params[:pay_arrears] == '1'
    unpaid_months = params[:unpaid_months] || []
    future_months = params[:future_months] || []

    if !pay_arrears && unpaid_months.empty? && future_months.empty?
      redirect_to payment_security_dashboard_index_path(address_id: address.id),
                  alert: 'Pilih minimal 1 item pembayaran'
      return
    end

    success = false
    total_amount = 0
    user_contributions_created = []

    UserContribution.transaction do
      # Handle arrears payment - arrears is number of months, not rupiah
      if pay_arrears && address.arrears.to_i > 0
        arrears_amount = address.arrears * address.current_contribution_rate
        total_amount += arrears_amount
        # Update arrears to 0
        address.update_column(:arrears, 0)
      end

      # Handle unpaid months
      unpaid_months.each do |month_year|
        month, year = month_year.split(',').map(&:to_i)

        # Check if already paid
        existing = UserContribution.find_by(address_id: address.id, month: month, year: year)
        next if existing

        expected_contribution = address.expected_contribution_for(month, year)
        month_text = UserContribution::MONTHNAMES.invert[month]

        user_contribution = UserContribution.new(
          address_id: address.id,
          month: month,
          year: year,
          contribution: expected_contribution,
          expected_contribution: expected_contribution,
          pay_at: Date.current,
          receiver_id: current_user.id,
          payment_type: payment_type,
          blok: address.block_address.gsub(/[^A-Za-z]/, '').upcase,
          description: "#{address.block_address} Pembayaran bulan #{month_text} #{year}"
        )

        if user_contribution.save
          user_contributions_created << user_contribution
          total_amount += expected_contribution
        else
          raise ActiveRecord::Rollback
        end
      end

      # Handle future months
      future_months.each do |month_year|
        month, year = month_year.split(',').map(&:to_i)

        # Check if already paid
        existing = UserContribution.find_by(address_id: address.id, month: month, year: year)
        next if existing

        expected_contribution = address.expected_contribution_for(month, year)
        month_text = UserContribution::MONTHNAMES.invert[month]

        user_contribution = UserContribution.new(
          address_id: address.id,
          month: month,
          year: year,
          contribution: expected_contribution,
          expected_contribution: expected_contribution,
          pay_at: Date.current,
          receiver_id: current_user.id,
          payment_type: payment_type,
          blok: address.block_address.gsub(/[^A-Za-z]/, '').upcase,
          description: "#{address.block_address} Pembayaran bulan #{month_text} #{year} (Bayar Di Muka)"
        )

        if user_contribution.save
          user_contributions_created << user_contribution
          total_amount += expected_contribution
        else
          raise ActiveRecord::Rollback
        end
      end

      # Create cash transaction
      if total_amount > 0
        description_parts = []
        description_parts << "Tunggakan Lama" if pay_arrears
        description_parts << "#{user_contributions_created.count} bulan" if user_contributions_created.any?

        CashTransaction.create(
          month: Date.current.month,
          year: Date.current.year,
          transaction_date: Date.current,
          transaction_type: CashTransaction::TYPE['DEBIT'],
          transaction_group: CashTransaction::GROUP['IURAN WARGA'],
          description: "#{address.block_address} pembayaran iuran (#{description_parts.join(' + ')})",
          total: total_amount,
          pic_id: current_user.id
        )
      end

      success = true
    end

    if success
      redirect_to security_dashboard_index_path,
                  notice: "Pembayaran berhasil! Total: Rp #{number_with_delimiter(total_amount, delimiter: '.')}"
    else
      redirect_to payment_security_dashboard_index_path(address_id: address.id),
                  alert: 'Gagal mencatat pembayaran'
    end
  end

  private

  def ensure_security_role
    unless current_user.is_security?
      redirect_to root_path, alert: 'Akses ditolak. Hanya untuk sekurity.'
    end
  end

  def get_security_addresses
    # Get blocks that this security is responsible for
    if current_user.pic_blok.present?
      bloks = current_user.pic_blok.split(',').map(&:strip)
      # Filter addresses by blocks
      Address.where("block_address ~ ?", "^(#{bloks.join('|')})")
    else
      Address.none
    end
  end

  def can_access_address?(address)
    return false unless current_user.pic_blok.present?

    bloks = current_user.pic_blok.split(',').map(&:strip)
    block_letter = address.block_letter

    bloks.include?(block_letter)
  end

  def build_months_payment_data(address, year)
    months_data = []
    1.upto(12) do |month_num|
      contribution_rate = address.expected_contribution_for(month_num, year)

      paid_contribution = UserContribution.find_by(
        address_id: address.id,
        month: month_num,
        year: year
      )

      months_data << {
        month: month_num,
        month_text: UserContribution::MONTHNAMES.invert[month_num],
        year: year,
        contribution_rate: contribution_rate,
        formatted_rate: format_currency(contribution_rate),
        is_paid: paid_contribution.present?,
        paid_amount: paid_contribution&.contribution,
        pay_date: paid_contribution&.pay_at&.strftime('%d/%m/%Y'),
        payment_id: paid_contribution&.id,
        receiver_name: paid_contribution&.receiver&.name
      }
    end
    months_data
  end

  def format_currency(amount)
    return '0' if amount.nil? || amount.zero?

    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end

  def get_accessible_blocks
    if current_user.pic_blok.present?
      current_user.pic_blok.split(',').map(&:strip).sort
    else
      []
    end
  end

  def calculate_unpaid_months(address, current_year, current_month)
    starting_year = AppSetting.starting_year

    # Calculate total months that should be paid from starting_year to current month
    total_months_should_pay = 0

    (starting_year..current_year).each do |year|
      if year == starting_year && year == current_year
        # Same year as starting and current
        total_months_should_pay += current_month
      elsif year == starting_year
        # First year - count from month 1 to December
        total_months_should_pay += 12
      elsif year == current_year
        # Current year - count from January to current month
        total_months_should_pay += current_month
      else
        # Middle years - count all 12 months
        total_months_should_pay += 12
      end
    end

    # Count how many months have been paid from starting_year to now
    paid_months_count = UserContribution.where(
      address_id: address.id
    ).where("year >= ?", starting_year)
     .where("year < ? OR (year = ? AND month <= ?)", current_year, current_year, current_month)
     .count

    # Calculate unpaid
    unpaid = total_months_should_pay - paid_months_count
    unpaid > 0 ? unpaid : 0
  end

  def get_unpaid_months_list(address, current_year, current_month)
    # Get all months from starting_year to current month
    starting_year = AppSetting.starting_year
    all_expected_months = []

    (starting_year..current_year).each do |year|
      month_start = (year == starting_year) ? 1 : 1
      month_end = (year == current_year) ? current_month : 12

      (month_start..month_end).each do |month|
        all_expected_months << { year: year, month: month }
      end
    end

    # Get all paid months
    paid_months = UserContribution.where(address_id: address.id)
                                   .where("year >= ?", starting_year)
                                   .pluck(:year, :month)
                                   .map { |y, m| { year: y, month: m } }

    # Find unpaid months
    unpaid_months = all_expected_months - paid_months
    unpaid_months.sort_by { |m| [m[:year], m[:month]] }
  end

  def get_future_months_list(address, current_year, current_month, months_ahead = 12)
    future_months = []
    year = current_year
    month = current_month

    months_ahead.times do
      # Move to next month
      month += 1
      if month > 12
        month = 1
        year += 1
      end

      # Check if already paid (in case someone paid in advance)
      already_paid = UserContribution.exists?(
        address_id: address.id,
        year: year,
        month: month
      )

      next if already_paid

      contribution_rate = address.expected_contribution_for(month, year)

      future_months << {
        month: month,
        month_text: UserContribution::MONTHNAMES.invert[month],
        year: year,
        contribution_rate: contribution_rate,
        formatted_rate: format_currency(contribution_rate),
        is_paid: false,
        is_future: true,
        paid_amount: nil,
        pay_date: nil,
        payment_id: nil,
        receiver_name: nil
      }
    end

    future_months
  end

  def get_expense_categories
    # Get categories from CashTransaction::GROUP that are typically expenses
    CashTransaction::GROUP.keys.select do |key|
      !['IURAN WARGA', 'PENDAPATAN LAIN'].include?(key)
    end.sort
  end
end
