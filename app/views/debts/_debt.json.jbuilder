# frozen_string_literal: true

json.extract! debt, :id, :user_id, :value, :description, :debt_date, :debt_type, :created_at, :updated_at
json.url debt_url(debt, format: :json)
