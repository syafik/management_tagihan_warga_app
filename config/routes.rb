# frozen_string_literal: true

Rails.application.routes.draw do
  get "arrears/index"
  namespace :admin do
      resources :addresses
      resources :address_contributions
      resources :app_settings
      resources :cash_flows
      resources :cash_infos
      resources :cash_transactions
      resources :contributions
      resources :debts
      resources :installments
      resources :notifications
      resources :template_transactions
      resources :total_contributions
      resources :users
      resources :user_addresses
      resources :user_contributions
      resources :user_debts
      resources :user_notifications

      root to: "addresses#index"
    end
  # Rails Admin removed, replaced with Administrate

  # Admin-only access to Solid Queue Dashboard
  authenticate :user, ->(u) { u.is_admin? } do
    mount SolidQueueDashboard::Engine, at: '/solid-queue'
  end

  # NOTE: Solid Queue doesn't have a built-in web interface
  # Use `bin/jobs` command to start workers
  # Use Rails console or logs to monitor jobs
  get '/api' => redirect('/swagger/dist/index.html?url=/apidocs/api-docs.json')
  devise_for :users, skip: :registrations, controllers: {
    sessions: 'users/sessions',
    passwords: 'users/passwords',
    unlocks: 'users/unlocks'
  }

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      mount_devise_token_auth_for 'User', at: 'auth',
                                          controllers: {
                                            sessions: 'api/v1/sessions',
                                            registrations: 'api/v1/registrations'
                                          }
      get '/home_page', to: 'home#home_page'
      get '/address/info/:block', to: 'home#address_info'
      get '/cash_flows/:year', to: 'home#cash_flows'
      get '/cash_transactions/:month/:year', to: 'home#cash_transactions'
      get '/users', to: 'home#user_lists'
      get '/profile', to: 'user#profile'
      get '/contributions', to: 'home#contributions'
      post '/user/reset_password_token', to: 'user#reset_password_token'
      post '/user/reset_password', to: 'user#reset_password'
      put '/user/profile/update', to: 'user#update_profile'
      get '/address/contribution_info', to: 'home#load_address_contribution_info'
      post '/pay_contribution', to: 'home#pay_contribution'
      post '/add_transaction', to: 'home#add_transaction'
      get '/notifications', to: 'home#notifications'
      get '/notifications/:id', to: 'home#notification_show'
      post '/notifications/add', to: 'home#add_notification'
      get '/debts', to: 'home#debts'
      post '/debts/add', to: 'home#add_debt'
      get '/installments', to: 'home#installments'
      get '/installments/:id', to: 'home#installment_transaction'
      post '/installments/add', to: 'home#add_installment'
      post '/installments/pay', to: 'home#pay_installment'
      post '/users/create', to: 'home#create_user'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'

  # Admin routes
  get 'backup_database', to: 'admin#backup_database', as: :backup_database

  # WhatsApp Login Routes (verification step)
  get '/phone_login/verify', to: 'phone_logins#verify', as: :verify_phone_login
  post '/phone_login/authenticate', to: 'phone_logins#authenticate', as: :authenticate_phone_login
  post '/phone_login/resend', to: 'phone_logins#resend', as: :resend_phone_login
  resources :users do
    collection do
      match :search, via: %i[get post]
    end
  end

  resources :cash_flows do
    collection do
      match :search, via: %i[get post]
      get 'generate_report/:year', to: 'cash_flows#generate_report', as: :generate_report
    end
  end

  resources :installments do
    collection do
      match :search, via: %i[get post]
    end
  end

  resources :debts do
    collection do
      match :search, via: %i[get post]
    end
  end

  resources :addresses do
    collection do
      match :search, via: %i[get post]
    end
    member do
      post :pay_arrears
    end
    resources :address_contributions
  end

  resources :notifications do
    collection do
      match :search, via: %i[get post]
    end
  end

  resources :contributions do
    collection do
      match :search, via: %i[get post]
    end
  end

  resources :cash_transactions do
    collection do
      match :search, via: %i[get post]
      get :import_data
      post :do_import_data
      get '/close_transaction/:year/:month', to: 'cash_transactions#close_transaction', as: :close_transaction
      get '/generate_report/:type/:year/:month', to: 'cash_transactions#generate_report', as: :generate_report
      get '/show_report/:type/:year/:month', to: 'cash_transactions#show_report', as: :show_report
    end
  end

  resources :user_contributions do
    collection do
      match :search, via: %i[get post]
      get :import_data
      post :do_import_data
      get :generate_tagihan
      get :import_arrears
      post :do_generate_data
      get :import_data_transfer
      post :do_import_data_transfer
      get :contribution_rate, to: 'user_contributions#get_contribution_rate'
      get :payment_status, to: 'user_contributions#payment_status'
      get :search_addresses, to: 'user_contributions#search_addresses'
    end
    member do
      get :contribution_by_address
    end
  end

  resources :app_settings
  resources :template_transactions

  # Payment routes (QRIS via Tripay)
  resources :payments, only: [:new, :create, :show], param: :reference do
    member do
      get :status # For AJAX status checks
    end
  end

  # Tripay webhook callback
  post '/tripay/callback', to: 'tripay_callbacks#callback'

  # Security Dashboard
  resources :security_dashboard, only: [:index] do
    collection do
      get :address_detail
      post :confirm_payment
      post :create_payment
      get 'payment/:address_id', to: 'security_dashboard#payment_page', as: :payment
      get :rekap_pembayaran
      get :new_expense
      post :create_expense
    end
  end
end
