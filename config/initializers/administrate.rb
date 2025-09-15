# Disable Administrate's CSS to avoid SassC compilation errors
if defined?(Administrate)
  # Override the asset loading to skip problematic CSS
  module Administrate
    class Engine < ::Rails::Engine
      initializer "administrate.assets.precompile" do |app|
        # Skip adding administrate CSS to avoid SassC compilation errors
        # app.config.assets.precompile += %w( administrate/application.css )
      end
    end
  end
end