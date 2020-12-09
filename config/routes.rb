Rails.application.routes.draw do
  
  devise_for :users, skip: :registrations, controllers: {
    sessions: 'users/sessions',
    passwords: 'users/passwords',
    unlocks: 'users/unlocks'
  }

  namespace :api, defaults: {format: :json} do
    namespace :v1 do 
      mount_devise_token_auth_for 'User', at: 'auth', 
      controllers: {
        sessions: 'api/v1/sessions',
        registrations: 'api/v1/registrations'
      }
      get '/cash_flows', to: "home#cash_flows"
      get '/profile', to: "home#profile"
      get '/contributions', to: "home#contributions"
    end
  end


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => "home#index"
  resources :users do
    collection do
      match :search, via: [:get, :post]
    end
  end

  resources :cash_flows do
    collection do
      match :search, via: [:get, :post]
    end
  end

  resources :installments do
    collection do
      match :search, via: [:get, :post]
    end
  end

  resources :debts do
    collection do
      match :search, via: [:get, :post]
    end
  end

  resources :addresses do
    collection do
      match :search, via: [:get, :post]
    end
  end

  resources :cash_transactions do
    collection do
      match :search, via: [:get, :post]
      get :import_data
      post :do_import_data
      get '/close_transaction/:year/:month', to: "cash_transactions#close_transaction", as: :close_transaction
      get '/generate_report/:type/:year/:month', to: "cash_transactions#generate_report", as: :generate_report
      get '/show_report/:type/:year/:month', to: "cash_transactions#show_report", as: :show_report
    end

  end

  resources :user_contributions do
    collection do
      match :search, via: [:get, :post]
      get :import_data
      post :do_import_data
      get :generate_tagihan
      post :do_generate_data
    end
    member do
      get :contribution_by_address
    end
  end
end
