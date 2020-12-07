json.extract! installment, :id, :description, :value, :transaction_type, :created_at, :updated_at
json.url installment_url(installment, format: :json)
