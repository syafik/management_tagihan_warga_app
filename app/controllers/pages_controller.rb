class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:privacy_policy, :terms_of_service, :support_contact]

  def privacy_policy
    # Privacy Policy page
  end

  def terms_of_service
    # Terms of Service page
  end

  def support_contact
    # Support Contact page
  end
end
