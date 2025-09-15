RailsAdmin.config do |config|
  # Try to bypass asset compilation issues
  config.asset_source = :webpacker if defined?(Webpacker)
  config.asset_source = :vite if defined?(ViteRuby)
  config.asset_source = :sprockets unless defined?(Webpacker) || defined?(ViteRuby)
  
  config.main_app_name = ['Management Tagihan Warga', 'Admin']

  # Authorize with Devise
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  # Authorization with CanCanCan
  config.authorize_with :cancancan

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end