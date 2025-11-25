Rails.application.routes.draw do
  # Health check
  get "health" => "health#show"
  get "up" => "rails/health#show", as: :rails_health_check

  # ActionCable WebSocket
  mount ActionCable.server => "/cable"

  # API routes
  namespace :api do
    namespace :v1 do
      # Golfers
      resources :golfers do
        member do
          post :check_in
          post :payment_details
          post :promote
        end
        collection do
          get :registration_status
          get :stats
        end
      end

      # Groups
      resources :groups do
        member do
          post :set_hole
          post :add_golfer
          post :remove_golfer
        end
        collection do
          post :update_positions
          post :batch_create
          post :auto_assign
        end
      end

      # Admins
      resources :admins do
        collection do
          get :me
        end
      end

      # Settings (singleton resource)
      resource :settings, only: [:show, :update]

      # Checkout
      post "checkout" => "checkout#create"
      post "checkout/confirm" => "checkout#confirm"
    end
  end
end
