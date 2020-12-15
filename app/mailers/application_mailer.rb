# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'pengurus@puriayana.com'
  layout 'mailer'
end
