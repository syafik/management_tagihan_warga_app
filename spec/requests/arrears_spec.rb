require 'rails_helper'

RSpec.describe "Arrears", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/arrears/index"
      expect(response).to have_http_status(:success)
    end
  end

end
