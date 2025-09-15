RailsAdmin.config do |config|
  config.asset_source = :sprockets
  
  # Disable problematic CSS compilation in production
  if Rails.env.production?
    config.included_models = []
    config.excluded_models = []
    
    # Configure basic theming without SASS issues
    config.main_app_name = ['Puri Ayana', 'Management']
  end
  
  # Main navigation
  config.main_app_name = ['Management Tagihan Warga', 'Admin']

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == CancanCan ==
  config.authorize_with :cancancan
  

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

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

  # Model configurations
  config.model 'Address' do
    navigation_label 'Address Management'
    weight 1
    
    object_label_method :display_name
    
    list do
      field :id
      field :block_address do
        label 'Address'
        formatted_value do
          bindings[:object].block_address.upcase
        end
      end
      field :current_contribution_rate do
        label 'Current Rate'
        formatted_value do
          amount = bindings[:object].current_contribution_rate
          amount ? "Rp. #{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}" : "Rp. 0"
        end
      end
      field :arrears
      field :free do
        label 'Free Address'
      end
      field :residents_count do
        label 'Total Residents'
        formatted_value do
          bindings[:object].residents_count
        end
      end
      field :head_of_family_name do
        label 'Head of Family'
        formatted_value do
          bindings[:object].head_of_family_name
        end
      end
    end
    
    show do
      field :block_address
      field :current_contribution_rate
      field :arrears
      field :free
      field :created_at
      field :updated_at
    end
    
    edit do
      field :block_address do
        help 'Address identifier (e.g., A12, B05)'
      end
      field :arrears do
        help 'Outstanding arrears amount'
      end
      field :free do
        help 'Check if this address is exempt from contributions'
      end
    end
  end

  config.model 'User' do
    navigation_label 'User Management'
    weight 2
    
    list do
      field :id
      field :name
      field :email
      field :phone_number do
        label 'Phone'
      end
      field :address do
        formatted_value do
          bindings[:object].address&.block_address&.upcase
        end
      end
      field :head_of_family do
        label 'Head of Family'
        formatted_value do
          bindings[:object].head_of_family? ? "✓ Kepala Keluarga" : "Anggota Keluarga"
        end
      end
      field :role_name
    end
    
    edit do
      field :name do
        help 'Full name of the user'
      end
      field :email do
        help 'Email address for login'
      end
      field :phone_number do
        label 'Phone'
        help 'Phone number with proper format'
      end
      field :address_id, :enum do
        label 'Primary Address'
        help 'Select primary address where user resides'
        enum do
          Address.all.order(:block_address).collect { |a| [a.block_address.upcase, a.id] }
        end
      end
      field :role, :enum do
        label 'Role'
        enum do
          { 'Warga' => 1, 'Admin' => 2, 'Sekuriti' => 3 }
        end
        help 'User role in the system'
      end
      field :pic_blok do
        label 'Block PIC'
        help 'If this user is a PIC (Person in Charge) for specific blocks'
      end
    end
    
    show do
      field :name
      field :email
      field :phone_number
      field :address do
        formatted_value do
          bindings[:object].address&.display_name
        end
      end
      field :role_name
      field :head_of_family do
        label 'Head of Family'
        formatted_value do
          bindings[:object].head_of_family? ? "Yes - Kepala Keluarga" : "No - Anggota Keluarga"
        end
      end
      field :pic_blok
      field :created_at
      field :updated_at
    end
  end

  config.model 'UserContribution' do
    navigation_label 'Financial Management'
    weight 3
    
    list do
      field :id
      field :address do
        formatted_value do
          bindings[:object].address&.block_address&.upcase
        end
      end
      field :month
      field :year
      field :contribution do
        formatted_value do
          amount = bindings[:object].contribution
          amount ? "Rp. #{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}" : "Rp. 0"
        end
      end
      field :pay_at
      field :receiver do
        formatted_value do
          bindings[:object].receiver&.name
        end
      end
      field :payment_type do
        formatted_value do
          bindings[:object].payment_type == 1 ? "Cash" : "Transfer"
        end
      end
    end
  end

  config.model 'Contribution' do
    navigation_label 'Configuration'
    weight 4
    
    list do
      field :id
      field :amount do
        formatted_value do
          amount = bindings[:object].amount
          amount ? "Rp. #{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}" : "Rp. 0"
        end
      end
      field :block
      field :effective_from
      field :active
    end
  end

  config.model 'AddressContribution' do
    navigation_label 'Configuration'
    weight 5
    
    list do
      field :id
      field :address do
        formatted_value do
          bindings[:object].address&.block_address&.upcase
        end
      end
      field :amount do
        formatted_value do
          amount = bindings[:object].amount
          amount ? "Rp. #{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}" : "Rp. 0"
        end
      end
      field :reason
      field :effective_from
      field :effective_until
      field :active
    end
    
    edit do
      field :address do
        help 'Select the address for this special contribution rate'
        associated_collection_scope do
          Proc.new { |field, object, view|
            Address.all.order(:block_address)
          }
        end
      end
      field :amount do
        help 'Special contribution amount for this address'
      end
      field :reason do
        help 'Reason for special rate (e.g., financial hardship, property type)'
      end
      field :effective_from do
        help 'Date when this special rate becomes effective'
      end
      field :effective_until do
        help 'Optional: Date when this special rate ends (leave blank for indefinite)'
      end
      field :active do
        help 'Whether this special rate is currently active'
      end
    end
  end
end
