# Re-enable Administrate's CSS now that we have proper layout
if defined?(Administrate)
  # Enable the asset loading for administrate CSS
  module Administrate
    class Engine < ::Rails::Engine
      initializer "administrate.assets.precompile" do |app|
        # Add administrate CSS to precompiled assets
        app.config.assets.precompile += %w( administrate/application.css administrate/application.js )
      end
    end
  end
end