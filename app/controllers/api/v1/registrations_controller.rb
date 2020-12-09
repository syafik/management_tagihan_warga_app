class Api::V1::RegistrationsController < DeviseTokenAuth::RegistrationsController

  skip_before_action :verify_authenticity_token

  def sign_up_params
    p "KESINI KITU"
    params.require(:registration).permit(:email, :password, :name, :phone_number)
  end

end
