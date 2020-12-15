# frozen_string_literal: true

json.array! @installments, partial: 'installments/installment', as: :installment
