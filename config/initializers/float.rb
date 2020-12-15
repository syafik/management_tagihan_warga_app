# frozen_string_literal: true

class Float
  def slim_format
    to_i == self ? to_i : self
  end
end
