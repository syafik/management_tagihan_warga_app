class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!, except: [:show_report]
  before_action :action_allowed, only: [:new, :create, :edit, :update]


  def action_allowed
    if current_user && current_user.role != 2
      redirect_to '/', alert: 'Anda tidak bisa mengakses action yang di tuju.'
    end
  end
end
