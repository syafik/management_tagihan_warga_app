# frozen_string_literal: true

json.array! @debts, partial: 'debts/debt', as: :debt
