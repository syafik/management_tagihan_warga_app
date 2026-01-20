# frozen_string_literal: true

class UserContributionsController < ApplicationController
  before_action :set_user_contribution, only: %i[show edit update destroy]

  # GET /user_contributions
  # GET /user_contributions.json
  def index
    @year_selected = (params[:year_eq] || Date.current.year).to_i
    @block_selected = params[:block_eq]
    @search_term = params[:search_address]
    @address_filter = params[:address_filter]

    # Debug logging
    Rails.logger.debug "Index - Year: #{@year_selected}, Block: #{@block_selected}, Search: #{@search_term}, Address Filter: #{@address_filter}"
    Rails.logger.debug "Params: #{params.inspect}"
    Rails.logger.debug "Current user role: #{current_user.role}"

    # Start with addresses based on user role
    if current_user.is_warga?
      # For Warga users, only show addresses they are affiliated with
      addresses = current_user.addresses

      # If address filter is specified, filter to specific address
      if @address_filter.present?
        addresses = addresses.where(id: @address_filter)
        Rails.logger.debug "Warga user - filtering to specific address: #{@address_filter}"
      else
        # Default: show only first address (primary or first available)
        first_address = current_user.primary_address || addresses.order(:block_address).first
        addresses = addresses.where(id: first_address&.id) if first_address
        @address_filter = first_address&.id
        Rails.logger.debug "Warga user - showing default first address: #{first_address&.block_address}"
      end

      Rails.logger.debug "Warga user - showing #{addresses.count} address(es)"
    else
      # For Admin/Security users, show all addresses
      addresses = Address.all

      # Default to Block A if no parameters provided and user is not Warga
      @block_selected = 'A' if @block_selected.blank? && @search_term.blank?

      # Filter by search term first (has priority)
      if @search_term.present?
        addresses = addresses.where("UPPER(block_address) LIKE UPPER(?)", "%#{@search_term}%")
        Rails.logger.debug "Searching for: %#{@search_term}% - Found: #{addresses.count}"
      elsif @block_selected.present?
        # Filter by block if no search term
        addresses = addresses.where("block_address LIKE ?", "#{@block_selected}%")
        Rails.logger.debug "Filtering by block: #{@block_selected}% - Found: #{addresses.count}"
      end
    end
    
    # Order by block letter first, then by number (alphanumeric sort)
    addresses = addresses.order(
      Arel.sql("SUBSTRING(block_address FROM '^[A-Za-z]+'), CAST(SUBSTRING(block_address FROM '[0-9]+') AS INTEGER)")
    )
    
    contribution_conditions = { year: @year_selected.to_i }
    ActiveRecord::Associations::Preloader.new(records: addresses, associations: :user_contributions,
                                              scope: UserContribution.where(contribution_conditions)).call
    
    @addresses = addresses
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def search
    @year_selected = (params[:year_eq] || Date.current.year).to_i
    @block_selected = params[:block_eq]
    @search_term = params[:search_address]
    
    # Debug logging
    Rails.logger.debug "Search - Year: #{@year_selected}, Block: #{@block_selected}, Search: #{@search_term}"
    Rails.logger.debug "Search Params: #{params.inspect}"
    Rails.logger.debug "Current user role: #{current_user.role}"
    
    # Start with addresses based on user role
    if current_user.is_warga?
      # For Warga users, only show addresses they are affiliated with
      addresses = current_user.addresses
      
      # If address filter is specified, filter to specific address
      if params[:address_filter].present?
        addresses = addresses.where(id: params[:address_filter])
        Rails.logger.debug "Warga user search - filtering to specific address: #{params[:address_filter]}"
      else
        # Default: show only first address (primary or first available)
        first_address = current_user.primary_address || addresses.order(:block_address).first
        addresses = addresses.where(id: first_address&.id) if first_address
        Rails.logger.debug "Warga user search - showing default first address: #{first_address&.block_address}"
      end
      
      Rails.logger.debug "Warga user search - showing #{addresses.count} address(es)"
    else
      # For Admin/Security users, show all addresses
      addresses = Address.all
      
      # Default to Block A if no parameters provided and user is not Warga
      @block_selected = 'A' if @block_selected.blank? && @search_term.blank?
      
      # Filter by search term first (has priority)
      if @search_term.present?
        addresses = addresses.where("UPPER(block_address) LIKE UPPER(?)", "%#{@search_term}%")
        Rails.logger.debug "Search - Searching for: %#{@search_term}% - Found: #{addresses.count}"
      elsif @block_selected.present?
        # Filter by block if no search term
        addresses = addresses.where("block_address LIKE ?", "#{@block_selected}%")
        Rails.logger.debug "Search - Filtering by block: #{@block_selected}% - Found: #{addresses.count}"
      end
    end

    # Order by block letter first, then by number (alphanumeric sort)
    addresses = addresses.order(
      Arel.sql("SUBSTRING(block_address FROM '^[A-Za-z]+'), CAST(SUBSTRING(block_address FROM '[0-9]+') AS INTEGER)")
    )

    contribution_conditions = { year: @year_selected.to_i }
    ActiveRecord::Associations::Preloader.new(records: addresses, associations: :user_contributions,
                                              scope: UserContribution.where(contribution_conditions)).call

    @addresses = addresses

    # Build redirect params
    redirect_params = {
      year_eq: @year_selected
    }
    redirect_params[:block_eq] = @block_selected if @block_selected.present?
    redirect_params[:search_address] = @search_term if @search_term.present?
    redirect_params[:address_filter] = params[:address_filter] if params[:address_filter].present?

    redirect_to user_contributions_path(redirect_params)
  end

  def import_data
    @year_selected = Date.current.year
    @month_selected = Date.current.month
  end

  def import_data_transfer
    @year_selected = Date.current.year
    @month_selected = Date.current.month
  end

  def do_import_data
    blok_name = Address::BLOK_NAME.invert[params[:blok].to_i]
    user = User.find(params[:receiver_id])
    unless user.pic_blok.split(',').map(&:strip).include?(blok_name)
      redirect_to import_data_user_contributions_path,
                  alert: "#{user.name} bukan merupakan PIC blok #{blok_name}." and return
    end
    if TotalContribution.where(month: params[:month], year: params[:year], blok: blok_name).exists?
      redirect_to import_data_user_contributions_path,
                  alert: "Month #{params[:month]}-#{params[:year]} sudah tergenerate." and return
    end

    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[params[:blok].to_i]
    (1..ws.num_rows).each do |row|
      block_address = ws[row, 2].strip
      contribution = ws[row, 3].strip
      bayar = ws[row, 5].strip
      tgl_bayar = ws[row, 6].strip
      months_paid = ws[row, 7].strip.split(",")
      next unless row >= 3

      address = Address.where(block_address: block_address).first
      next unless address

      year_selected = params[:year].to_i
      0.upto(bayar.to_i - 1) do |i|
        month_selected = months_paid[i].to_i
        month_before = i.zero? ? month_selected : months_paid[i - 1].to_i
        year_selected = month_before == 12 && month_selected < month_before ? (year_selected + 1) : year_selected

        # Get the expected contribution rate for this specific month/year
        # This will use the Contribution model to get the correct rate based on:
        # 1. Address-specific rates (AddressContribution)
        # 2. Block-specific rates (Contribution for this block)
        # 3. Global rates (Contribution with no block specified)
        expected_amount = address.expected_contribution_for(month_selected, year_selected)

        # Use the expected amount as the paid amount since the spreadsheet shows 
        # they paid the correct amount for that period
        paid_amount = expected_amount

        UserContribution.create(
          month: month_selected,
          year: year_selected,
          address_id: address.id,
          contribution: paid_amount,
          expected_contribution: expected_amount,
          receiver_id: params[:receiver_id],
          pay_at: tgl_bayar.to_date,
          blok: blok_name,
          payment_type: 1
        )
      end
    end

    t_date = Date.parse("#{params[:year]}-#{params[:month]}-20")
    CashTransaction.create(
      month: params[:month],
      year: params[:year],
      transaction_date: params[:transaction_date],
      transaction_type: CashTransaction::TYPE['DEBIT'],
      transaction_group: CashTransaction::GROUP['IURAN WARGA'],
      description: "Pendapatan Iuran Warga Blok #{blok_name}",
      total: UserContribution.where(pay_at: t_date.beginning_of_month..t_date.end_of_month, blok: blok_name, receiver_id: user.id).sum(&:contribution),
      pic_id: user.id
    )
    redirect_to user_contributions_path, notice: 'Import data success'
  end

  def do_import_data_transfer
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[6]
    total_transfer_amount = 0
    (1..ws.num_rows).each do |row|
      block_address = ws[row, 1].strip
      bayar = ws[row, 2].strip
      contribution = ws[row, 3].strip
      tgl_bayar = ws[row, 4].strip
      bulan_bayar = ws[row, 5].strip
      months = bulan_bayar.split(',')
      amount = contribution.gsub(/[^\d]/, '').to_f

      address = Address.where(block_address: block_address.upcase).first
      next unless address

      year_selected = params[:year].to_i

      today = Time.zone.today
      current_year = today.year

      bayar.to_i.times do |i|
        month_selected = months[i]
        if month_selected.include?('-')
          # Format: "12-2024"
          month_str, year_str = month_selected.split('-')
          month = month_str.to_i
          year = year_str.to_i
        else
          # Format: "1", "2", dst — tahun mengikuti current_year_track
          month = month_selected.to_i
          year = current_year
        end
        UserContribution.create!(
          month: month,
          year: year,
          address_id: address.id,
          contribution: amount,
          receiver_id: params[:receiver_id],
          pay_at: tgl_bayar&.to_date.presence || "#{month}-#{year}-20",
          blok: block_address[0].upcase,
          payment_type: 2
        )
        total_transfer_amount += amount
      end
    end

    CashTransaction.create(
      month: params[:month],
      year: params[:year],
      transaction_date: params[:transaction_date],
      transaction_type: CashTransaction::TYPE['DEBIT'],
      transaction_group: CashTransaction::GROUP['IURAN WARGA'],
      description: "Pendapatan Iuran Warga Yang Transfer",
      total: total_transfer_amount,
      pic_id: params[:receiver_id]
    )
    redirect_to user_contributions_path, notice: 'Import data transfer success'
  end

  def import_arrears_x
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    0.upto(3) do |blok|
      ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[blok]
      (1..ws.num_rows).each do |row|
        block_address = ws[row, 2].strip
        arrear = ws[row, 4].strip
        next unless row >= 3

        address = Address.where(block_address: block_address).first
        next unless address

        address.update_column(:arrears, arrear)
      end
    end
  end

  # GET /user_contributions/1
  # GET /user_contributions/1.json
  def show
    @address = @user_contribution.address
    @user_contributions = @address.user_contributions
  end

  # GET /user_contributions/new
  def new
    @user_contribution = UserContribution.new
    @year_selected = (params[:year] || [Date.current.year, AppSetting.starting_year].max).to_i
    @month_info = generate_month_info(@year_selected)
    @selected_address_id = params[:address_id]

    # Load arrears info if address is pre-selected
    if @selected_address_id.present?
      @selected_address = Address.find_by(id: @selected_address_id)
      @arrears_months = @selected_address&.arrears || 0
      @arrears_rate = @selected_address&.expected_contribution_for(1, Date.current.year) || 0
    end
  end

  # GET /user_contributions/1/edit
  def edit; end

  # POST /user_contributions
  # POST /user_contributions.json
  def create
    success = false
    total_contribution_amount = 0
    address = Address.find_by(id: params[:user_contribution][:address_id])

    if address.nil?
      flash[:error] = "Alamat tidak ditemukan"
      redirect_to new_user_contribution_path and return
    end

    user_contributions_created = []
    arrears_paid_count = 0

    # Get arrears payment data
    pay_arrears = Array(params[:pay_arrears]).reject(&:blank?)
    arrears_rate = address.expected_contribution_for(1, Date.current.year)

    UserContribution.transaction do
      # Handle arrears payment first
      pay_arrears.each do |arrears_index|
        total_contribution_amount += arrears_rate
        arrears_paid_count += 1
        Rails.logger.info "Processing arrears #{arrears_index}: amount=#{arrears_rate}"
      end

      # Update arrears counter
      if arrears_paid_count > 0
        old_arrears = address.arrears.to_i
        new_arrears = [old_arrears - arrears_paid_count, 0].max
        Rails.logger.info "Updating arrears: #{old_arrears} -> #{new_arrears}"
        address.update_column(:arrears, new_arrears)
      end

      # Handle regular month payments
      if params[:user_contribution_month].present?
        params[:user_contribution_month].each do |value|
          month, month_text, year = value.strip.split(",")

          # Get the expected contribution for this specific address, month, and year
          expected_contribution = address.expected_contribution_for(month.to_i, year.to_i)

          params[:user_contribution][:month] = month.to_i
          params[:user_contribution][:year] = year.to_i
          params[:user_contribution][:description] = "#{address.block_address} Pembayaran bulan #{month_text} #{year}"
          params[:user_contribution][:contribution] = expected_contribution
          params[:user_contribution][:expected_contribution] = expected_contribution

          @user_contribution = UserContribution.new(user_contribution_params)
          @user_contribution.blok = @user_contribution.address.block_address.gsub(/[^A-Za-z]/,'') rescue ''

          if @user_contribution.save
            user_contributions_created << @user_contribution
            total_contribution_amount += expected_contribution
          else
            raise ActiveRecord::Rollback
          end
        end
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
        transaction_month = first_contribution&.month || Date.current.month
        transaction_year = first_contribution&.year || Date.current.year

        CashTransaction.create(
          month: transaction_month,
          year: transaction_year,
          transaction_date: first_contribution&.pay_at || Date.current,
          transaction_type: CashTransaction::TYPE['DEBIT'],
          transaction_group: CashTransaction::GROUP['IURAN WARGA'],
          description: "#{address.block_address} pembayaran iuran (#{description_parts.join(' + ')})",
          total: total_contribution_amount,
          pic_id: current_user.id
        )
      end

      success = true
    end

    # Send payment notification if successful
    if success && (user_contributions_created.any? || arrears_paid_count > 0)
      contribution_ids = user_contributions_created.map(&:id)
      SendPaymentNotificationJob.perform_later(contribution_ids, nil, arrears_paid_count, total_contribution_amount, address.id)
    end

    respond_to do |format|
      if success
        format.html { redirect_to contribution_by_address_user_contribution_path(@user_contribution.address), notice: 'User contribution was successfully created.' }
        format.json { render :show, status: :created, location: @user_contribution }
      else
        format.html { render :new }
        format.json { render json: @user_contribution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_contributions/1
  # PATCH/PUT /user_contributions/1.json
  def update
    respond_to do |format|
      if @user_contribution.update(user_contribution_params)
        format.html { redirect_to @user_contribution, notice: 'User contribution was successfully updated.' }
        format.json { render :show, status: :ok, location: @user_contribution }
      else
        format.html { render :edit }
        format.json { render json: @user_contribution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_contributions/1
  # DELETE /user_contributions/1.json
  def destroy
    @user_contribution.destroy
    respond_to do |format|
      format.html { redirect_to user_contributions_url, notice: 'User contribution was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def generate_tagihan
    @year_selected = Date.current.year
    @month_selected = Date.current.month
  end

  def import_arrears
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    Address::BLOK_NAME.each do |_key, value|
      ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[value]
      (1..ws.num_rows).each do |row|
        if row == 1
          ws[row, 1] =
            "DAFTAR IURAN BULAN WARGA  #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}  BLOK #{Address::BLOK_NAME.invert[value]}"
        elsif row >= 3
          block_address = ws[row, 2].strip
          contribution = ws[row, 3].strip
          tagihan = ws[row, 4].strip
          bayar = ws[row, 5].strip
          address = Address.where(block_address: block_address).first
          if address
            total_paid_should_be = (year.to_i - 2024) * 12 + month.to_i
            ws[row, 4] = total_paid_should_be - total_paid
            ws[row, 5] = nil
            ws[row, 6] = nil
            ws[row, 7] = nil
          end
        end
      end
      ws.save
    end
  end

  def do_generate_data
    month = begin
      params[:month]
    rescue StandardError
      Date.current.month
    end
    year = begin
      params[:year]
    rescue StandardError
      Date.current.year
    end
    # TODO: how to get active contiburion based on month and year and by address.. we have lllop te get address below
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
    Address::BLOK_NAME.each do |_key, value|
      ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[value]
      (1..ws.num_rows).each do |row|
        if row == 1
          ws[row, 1] =
            "DAFTAR IURAN BULAN WARGA  #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}  BLOK #{Address::BLOK_NAME.invert[value]}"
        elsif row >= 3
          block_address = ws[row, 2].strip
          address = Address.where(block_address: block_address).first
          if address
            # Get the active contribution rate for this address for the specific month/year
            contribution = address.expected_contribution_for(month.to_i, year.to_i)
            total_paid = UserContribution.where(address_id: address.id).where(year: Time.now.year).count
            tagihan = month.to_i - total_paid
            ws[row, 3] = contribution
            ws[row, 4] = address.free? ? 0 : (tagihan.positive? ? tagihan : 0)
            ws[row, 5] = nil

            ws[row, 6] = nil
            ws[row, 7] = nil
          end
        end
      end
      ws.save
    end

    # PENGELUARAN WORKSHEET
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[5]
    (1..ws.num_rows).each do |row|
      if row == 1
        ws[row, 1] =
          "LAPORAN TRANSAKSI PEMAKAIAN KAS BULAN #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}"
      elsif row >= 3
        ws[row, 1] = nil
        ws[row, 2] = nil
        ws[row, 3] = nil
      end
    end
    ws.save

    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[7]
    (1..ws.num_rows).each do |row|
      if row == 1
        ws[row, 1] =
          "SYAFIK - LAPORAN TRANSAKSI PEMAKAIAN KAS BULAN #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}"
      elsif row >= 3
        ws[row, 1] = nil
        ws[row, 2] = nil
        ws[row, 3] = nil
      end
    end
    ws.save

    # LIST TRANSFER WORKSHEET
    ws = session.spreadsheet_by_key('1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk').worksheets[6]
    (1..ws.num_rows).each do |row|
      if row == 1
        ws[row, 1] =
          "DAFTAR IURAN TRANSFER #{UserContribution::MONTHNAMES.invert[month.to_i].upcase} #{year}"
      elsif row >= 3
        ws[row, 1] = nil
        ws[row, 2] = nil
        ws[row, 3] = nil
        ws[row, 4] = nil
        ws[row, 5] = nil
      end
    end
    ws.save

    respond_to do |format|
      format.html { redirect_to user_contributions_url, notice: 'Data tagihan was successfully generated.' }
      format.json { head :no_content }
    end
  end

  def contribution_by_address
    @address = Address.find(params[:id])
    @year_selected = (params[:year] || Date.current.year).to_i
    @contributions = @address.user_contributions.where(year: @year_selected)
    @all_contributions = @address.user_contributions # Keep all for overall stats if needed
  end

  def get_contribution_rate
    address_id = params[:address_id]
    month = params[:month] || Date.current.month
    year = params[:year] || Date.current.year
    
    if address_id.present?
      address = Address.find(address_id)
      rate = address.expected_contribution_for(month.to_i, year.to_i)
      
      render json: { 
        success: true, 
        rate: rate,
        formatted_rate: format_currency(rate)
      }
    else
      render json: { success: false, error: 'Address ID required' }
    end
  end

  def payment_status
    address_id = params[:address_id]
    year = (params[:year] || Date.current.year).to_i

    if address_id.present?
      address = Address.find(address_id)

      months_data = build_months_payment_data(address, year)

      # Get arrears info
      arrears_months = address.arrears || 0
      arrears_rate = address.expected_contribution_for(1, Date.current.year)

      render json: {
        success: true,
        months: months_data,
        address_name: address.block_address&.upcase,
        arrears: arrears_months,
        arrears_rate: arrears_rate
      }
    else
      render json: { success: false, error: 'Address ID required' }
    end
  end

  def search_addresses
    query = params[:q]&.strip
    
    if query.blank? || query.length < 2
      render json: []
      return
    end

    # Search by block address or head of family name
    addresses = Address.left_joins(:head_of_family)
                      .where(
                        "UPPER(addresses.block_address) LIKE UPPER(?) OR UPPER(users.name) LIKE UPPER(?)",
                        "%#{query}%", "%#{query}%"
                      )
                      .includes(:head_of_family)
                      .order('addresses.block_address')
                      .limit(10)

    results = addresses.map do |address|
      head_name = address.head_of_family&.name&.upcase
      display_text = head_name.present? ? "#{address.block_address&.upcase} - #{head_name}" : address.block_address&.upcase
      {
        id: address.id,
        block_address: address.block_address&.upcase,
        head_of_family_name: head_name,
        display_text: display_text
      }
    end

    render json: results
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user_contribution
    @user_contribution = UserContribution.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_contribution_params
    params.require(:user_contribution).permit(:address_id, :year, :month, :contribution, :pay_at, :receiver_id, :payment_type, :blok,
                                              :description, :transaction_date, :imported_cash_transaction)
  end

  def generate_month_info(year = Date.current.year)
    months_info = []

    # Generate all 12 months for the given year
    1.upto(12) do |month_num|
      date = Date.new(year, month_num, 1)
      month_name = UserContribution::MONTHNAMES.invert[month_num]

      months_info << {
        month: month_num.to_s,
        month_text: month_name,
        year: year,
        date: date
      }
    end

    months_info
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
        payment_id: paid_contribution&.id
      }
    end
    months_data
  end

  def format_currency(amount)
    return '0' if amount.nil? || amount.zero?
    
    # Format with Indonesian locale (using period as thousands separator)
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end
end
