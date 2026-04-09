require 'test_helper'

class TripayServiceTest < ActiveSupport::TestCase
  test 'build_return_url uses provided base_url when app_url is not set' do
    original_app_url = ENV['APP_URL']
    original_rails_host = ENV['RAILS_HOST']
    ENV.delete('APP_URL')
    ENV.delete('RAILS_HOST')

    service = TripayService.new
    url = service.send(:build_return_url, 'PAY123', base_url: 'https://example.com/')

    assert_equal 'https://example.com/payments/PAY123', url
  ensure
    ENV['APP_URL'] = original_app_url
    ENV['RAILS_HOST'] = original_rails_host
  end

  test 'build_return_url raises in production when no host source is available' do
    original_app_url = ENV['APP_URL']
    original_rails_host = ENV['RAILS_HOST']
    ENV.delete('APP_URL')
    ENV.delete('RAILS_HOST')

    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      service = TripayService.new

      error = assert_raises(TripayService::TripayError) do
        service.send(:build_return_url, 'PAY123')
      end

      assert_match 'request host is unavailable', error.message
    end
  ensure
    ENV['APP_URL'] = original_app_url
    ENV['RAILS_HOST'] = original_rails_host
  end
end
