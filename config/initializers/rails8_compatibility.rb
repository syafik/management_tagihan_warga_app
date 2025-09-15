# Rails 8 Compatibility fixes
# Some gems may still reference deprecated Active Support features

if Rails::VERSION::MAJOR >= 8
  # Fix for gems that still use active_support/basic_object
  begin
    require 'active_support/basic_object'
  rescue LoadError
    # Create a compatibility shim for gems that still need BasicObject
    module ActiveSupport
      BasicObject = ::BasicObject
    end
  end

  # Fix for gems that still use active_support/proxy_object
  begin
    require 'active_support/proxy_object'
  rescue LoadError
    # Create a compatibility shim for ProxyObject (removed in Rails 8)
    module ActiveSupport
      class ProxyObject < ::BasicObject
        undef_method :==, :equal?, :!, :!=
      end
    end
  end
end