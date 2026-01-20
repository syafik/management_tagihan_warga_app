# frozen_string_literal: true

class PaymentReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  helper_method :payment_type_label

  def index
    @selected_month = (params[:month] || Date.current.month).to_i
    @selected_year = (params[:year] || Date.current.year).to_i
    @selected_block = params[:block].presence
    @selected_pic_id = params[:pic_id].presence

    @blocks = Address::BLOK_NAME.keys.sort
    @pics = User.where(id: UserContribution.select(:receiver_id).distinct).order(:name)

    @addresses = base_address_scope
    contributions = filtered_contributions(@addresses.map(&:id))

    @contributions_by_address = contributions.group_by(&:address_id)
    build_totals(contributions)
    @rows = build_rows
  end

  private

  def ensure_admin!
    return if current_user&.is_admin?

    redirect_to root_path, alert: 'Hanya admin yang bisa mengakses halaman ini.'
  end

  def base_address_scope
    scope = Address.includes(:head_of_family, :users).order(:block_address)
    return scope unless @selected_block.present?

    scope.where('block_address ILIKE ?', "#{@selected_block}%")
  end

  def filtered_contributions(address_ids)
    scope = UserContribution.includes(:address, :receiver)
                             .where('EXTRACT(month FROM pay_at) = ?', @selected_month)
                             .where('EXTRACT(year FROM pay_at) = ?', @selected_year)
                             .where(address_id: address_ids)
    scope = scope.where(blok: @selected_block) if @selected_block.present?
    scope = scope.where(receiver_id: @selected_pic_id) if @selected_pic_id.present?
    scope
  end

  def build_rows
    @addresses.map do |address|
      entries = @contributions_by_address[address.id] || []

      {
        address_label: address.block_address.to_s.upcase,
        owner: owner_name(address),
        months_paid: entries_months(entries),
        payment_types: entries_payment_types(entries),
        total: entries_total(entries)
      }
    end
  end

  def entries_months(entries)
    return '' if entries.empty?

    entries.map do |entry|
      month_value = entry.month || entry.pay_at&.month
      year_value = entry.year || entry.pay_at&.year
      [month_value, year_value].all? ? "#{month_name(month_value)} #{year_value}" : nil
    end.compact.uniq.join(', ')
  end

  def entries_payment_types(entries)
    return '' if entries.empty?

    entries.map { |entry| payment_type_label(entry.payment_type) }.compact.uniq.join(', ')
  end

  def entries_total(entries)
    entries.sum { |entry| entry.contribution.to_f }
  end

  def owner_name(address)
    return address.head_of_family_name if address.head_of_family_name.present? && address.head_of_family_name != 'Tidak ada'

    names = address.resident_users.limit(3).pluck(:name)
    return names.join(', ') if names.any?

    '—'
  end

  def month_name(month_number)
    return '' unless month_number

    I18n.t('date.month_names')[month_number] || Date::MONTHNAMES[month_number]
  end

  def payment_type_label(payment_type)
    case payment_type
    when UserContribution::PAYMENT_TYPES['CASH']
      'Cash'
    when UserContribution::PAYMENT_TYPES['TRANSFER']
      'Transfer'
    when UserContribution::PAYMENT_TYPES['QRIS']
      'QRIS'
    else
      nil
    end
  end

  def build_totals(contributions)
    @totals_by_block = Hash.new { |hash, key| hash[key] = default_totals }
    @overall_totals = default_totals

    contributions.each do |entry|
      block_key = entry.blok.presence || entry.address&.block_letter || 'Unknown'
      amount = entry.contribution.to_f
      type_key = payment_type_key(entry.payment_type)

      if type_key
        @totals_by_block[block_key][type_key] += amount
        @overall_totals[type_key] += amount
      end

      @totals_by_block[block_key][:total] += amount
      @overall_totals[:total] += amount
    end
  end

  def default_totals
    { cash: 0.0, transfer: 0.0, qris: 0.0, total: 0.0 }
  end

  def payment_type_key(payment_type)
    case payment_type
    when UserContribution::PAYMENT_TYPES['CASH']
      :cash
    when UserContribution::PAYMENT_TYPES['TRANSFER']
      :transfer
    when UserContribution::PAYMENT_TYPES['QRIS']
      :qris
    else
      nil
    end
  end
end
