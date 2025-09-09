# frozen_string_literal: true

class Admin::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  private

  def ensure_admin!
    redirect_to root_path, alert: 'Access denied. Admin privileges required.' unless current_user&.is_admin?
  end
end