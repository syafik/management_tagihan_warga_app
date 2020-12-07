json.extract! user_contribution, :id, :user_id, :year, :month, :contribution, :pay_at, :receiver_id, :description, :created_at, :updated_at
json.url user_contribution_url(user_contribution, format: :json)
