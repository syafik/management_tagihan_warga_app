# frozen_string_literal: true

# head class for activerecord

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
