class ArrearsController < ApplicationController
  def index
    # Get threshold from settings (default: 2 months)
    @threshold = Setting.arrears_threshold_months

    # Calculate cutoff date (1 month before current month)
    # If current month is October 2025, cutoff is September 2025
    current_date = Date.current
    cutoff_date = current_date - 1.month

    # Starting from January 2025
    start_date = Date.new(2025, 1, 1)

    # Calculate how many months from Jan 2025 to cutoff date
    # Example: Jan 2025 to Sep 2025 = 9 months
    months_should_pay = ((cutoff_date.year - start_date.year) * 12) + (cutoff_date.month - start_date.month) + 1

    # Get all addresses that are NOT free
    # Skip addresses with free flag = true
    # Include addresses even if they don't have residents
    addresses = Address.includes(:user_contributions, :head_of_family, :residents)
                       .where(free: [false, nil])

    # Calculate arrears for each address
    @arrears_data = addresses.map do |address|
      # Count payments made in 2025 only (from Jan 2025 to cutoff date)
      total_paid_2025 = address.user_contributions
                               .where('pay_at >= ? AND pay_at <= ?', start_date, cutoff_date.end_of_month)
                               .count

      # Get initial arrears from database (tunggakan dari sebelum 2025)
      initial_arrears = address.arrears || 0

      # Calculate current arrears
      # Formula: (months should pay in 2025) - (payments made in 2025) + (arrears from before 2025)
      arrears_months = months_should_pay - total_paid_2025 + initial_arrears

      {
        address: address,
        arrears_months: arrears_months,
        months_should_pay: months_should_pay,
        total_paid_2025: total_paid_2025,
        initial_arrears: initial_arrears,
        head_of_family: address.head_of_family,
        residents: address.residents
      }
    end.select { |data| data[:arrears_months] >= @threshold }
       .sort_by { |data| -data[:arrears_months] }

    @total_arrears_count = @arrears_data.size
    @cutoff_date = cutoff_date
    @start_date = start_date
    @months_should_pay = months_should_pay
  end
end
