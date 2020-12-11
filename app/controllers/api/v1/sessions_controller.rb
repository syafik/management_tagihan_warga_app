class Api::V1::SessionsController < DeviseTokenAuth::SessionsController
  skip_before_action :verify_authenticity_token, only: :create, raise: false

  def create
    p params
    super
  end

end
