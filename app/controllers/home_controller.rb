# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @starting_year = AppSetting.starting_year
    @current_year = Date.current.year
    @year_selected = (params[:year] || @current_year).to_i
    @year_selected = [[@year_selected, @starting_year].max, @current_year].min
    @starting_balance = AppSetting.starting_balance
    
    # Monthly income/outcome data for current year (2025)
    begin
      @monthly_financial_data = calculate_monthly_financial_data
      Rails.logger.debug "Monthly financial data: #{@monthly_financial_data.inspect}"
    rescue => e
      Rails.logger.error "Failed to calculate monthly financial data: #{e.message}"
      @monthly_financial_data = []
    end
    
    # Contribution statistics (only for non-security users)
    unless current_user&.is_security?
      begin
        @contribution_percentage = calculate_contribution_percentage
        @overall_cash_balance = calculate_overall_cash_balance
        @monthly_contribution_stats = calculate_monthly_contribution_stats
        @total_income_year = calculate_total_income_year
        @total_outcome_year = calculate_total_outcome_year
        @year_balance = @total_income_year - @total_outcome_year
      rescue => e
        Rails.logger.error "Failed to calculate contribution data: #{e.message}"
        @contribution_percentage = 0
        @overall_cash_balance = 0
        @monthly_contribution_stats = []
        @total_income_year = 0
        @total_outcome_year = 0
        @year_balance = 0
      end
    end
    
    # General statistics for all users
    @total_residents = User.count
    @total_addresses = Address.count
    
    # Security-specific data (also available to admin)
    if current_user&.is_security? || current_user&.is_admin?
      begin
        @recent_activities = get_recent_security_activities
        @monthly_resident_stats = calculate_monthly_resident_stats
      rescue => e
        Rails.logger.error "Failed to calculate security data: #{e.message}"
        @recent_activities = { recent_registrations: 0, recent_address_updates: 0, active_residents_this_month: 0 }
        @monthly_resident_stats = []
      end
    end
  end

  private

  def calculate_monthly_financial_data
    begin
      (1..12).map do |month|
        if @year_selected == Date.current.year && month == Date.current.month
          next {
            month: month,
            month_name: Date.new(@year_selected, month, 1).strftime('%B'),
            income: 0,
            outcome: 0,
            net: 0
          }
        end

        income = CashTransaction.where(
          transaction_type: CashTransaction::TYPE['DEBIT'],
          month: month,
          year: @year_selected
        ).sum(:total) || 0
        
        outcome = CashTransaction.where(
          transaction_type: CashTransaction::TYPE['KREDIT'],
          month: month,
          year: @year_selected
        ).sum(:total) || 0
        
        {
          month: month,
          month_name: Date.new(@year_selected, month, 1).strftime('%B'),
          income: income,
          outcome: outcome,
          net: income - outcome
        }
      end
    rescue => e
      Rails.logger.error "Error calculating monthly financial data: #{e.message}"
      # Return fallback data with zero values
      (1..12).map do |month|
        {
          month: month,
          month_name: Date.new(@year_selected, month, 1).strftime('%B'),
          income: 0,
          outcome: 0,
          net: 0
        }
      end
    end
  end

  def calculate_contribution_percentage
    total_addresses = Address.count
    return 0 if total_addresses == 0
    
    # Count unique addresses that have paid this year
    paid_addresses = UserContribution.where(year: @year_selected)
                                   .joins(:address)
                                   .select('addresses.id')
                                   .distinct
                                   .count

    (paid_addresses.to_f / total_addresses * 100).round(2)
  end

  def calculate_overall_cash_balance
    start_date = Date.new(@starting_year, 1, 1)
    end_date = Date.current.beginning_of_month - 1.day

    total_income = CashTransaction.where(
      transaction_type: CashTransaction::TYPE['DEBIT'],
      transaction_date: start_date..end_date
    ).sum(:total)

    total_outcome = CashTransaction.where(
      transaction_type: CashTransaction::TYPE['KREDIT'],
      transaction_date: start_date..end_date
    ).sum(:total)

    @starting_balance + total_income - total_outcome
  end

  def calculate_monthly_contribution_stats
    begin
      (1..12).map do |month|
        contributions_count = UserContribution.where(month: month, year: @year_selected).count || 0
        contributions_amount = UserContribution.where(month: month, year: @year_selected).sum(:contribution) || 0
        
        {
          month: month,
          month_name: Date.new(@year_selected, month, 1).strftime('%B'),
          count: contributions_count,
          amount: contributions_amount
        }
      end
    rescue => e
      Rails.logger.error "Error calculating monthly contribution stats: #{e.message}"
      # Return fallback data with zero values
      (1..12).map do |month|
        {
          month: month,
          month_name: Date.new(@current_year, month, 1).strftime('%B'),
          count: 0,
          amount: 0
        }
      end
    end
  end

  def calculate_total_income_year
    scope = CashTransaction.where(
      transaction_type: CashTransaction::TYPE['DEBIT'],
      year: @year_selected
    )
    scope = scope.where.not(month: Date.current.month) if @year_selected == Date.current.year
    scope.sum(:total)
  end

  def calculate_total_outcome_year
    scope = CashTransaction.where(
      transaction_type: CashTransaction::TYPE['KREDIT'],
      year: @year_selected
    )
    scope = scope.where.not(month: Date.current.month) if @year_selected == Date.current.year
    scope.sum(:total)
  end

  def get_recent_security_activities
    # Recent user registrations, address changes, etc.
    {
      recent_registrations: User.where('created_at >= ?', 30.days.ago).count,
      recent_address_updates: Address.where('updated_at >= ?', 30.days.ago).count,
      active_residents_this_month: UserContribution.where(
        month: Date.current.month,
        year: Date.current.year
      ).count
    }
  end

  def calculate_monthly_resident_stats
    begin
      (1..12).map do |month|
        active_residents = UserContribution.where(month: month, year: @year_selected)
                                         .joins(:address)
                                         .select('addresses.id')
                                         .distinct
                                         .count || 0
        
        {
          month: month,
          month_name: Date.new(@year_selected, month, 1).strftime('%B'),
          active_residents: active_residents
        }
      end
    rescue => e
      Rails.logger.error "Error calculating monthly resident stats: #{e.message}"
      # Return fallback data with zero values  
      (1..12).map do |month|
        {
          month: month,
          month_name: Date.new(@current_year, month, 1).strftime('%B'),
          active_residents: 0
        }
      end
    end
  end

end
