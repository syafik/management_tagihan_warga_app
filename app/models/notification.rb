class Notification < ApplicationRecord

  def self.ransack_predicates
    [
        ["Contains", 'cont'],
        ["Equal", 'eq'],
    ]
  end


end
