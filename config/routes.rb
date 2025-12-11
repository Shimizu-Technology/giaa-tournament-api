Rails.application.routes.draw do
  # Health check
  get "health" => "health#show"
  get "up" => "rails/health#show", as: :rails_health_check

  # ActionCable WebSocket
  mount ActionCable.server => "/cable"

  # API routes
  namespace :api do
    namespace :v1 do
      # Tournaments
      resources :tournaments do
        member do
          post :archive
          post :copy
          post :open
          post :close
        end
        collection do
          get :current
        end
      end

      # Golfers
      resources :golfers do
        member do
          post :check_in
          post :payment_details
          post :promote
          post :demote
          post :update_payment_status
          post :cancel
          post :refund
          post :mark_refunded
          post :send_payment_link
          post :toggle_employee
        end
        collection do
          get :registration_status
          get :stats
          post :bulk_set_employee
          post :bulk_send_payment_links
        end
      end
      
      # Payment Links (public endpoints)
      get "payment_links/:token" => "payment_links#show"
      post "payment_links/:token/checkout" => "payment_links#create_checkout"

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

      # Activity Logs
      resources :activity_logs, only: [:index] do
        collection do
          get :summary
          get 'golfer/:golfer_id', action: :golfer_history, as: :golfer_history
        end
      end

      # Employee Numbers
      resources :employee_numbers, only: [:index, :create, :update, :destroy] do
        member do
          post :release
        end
        collection do
          post :bulk_create
          post :validate  # Public endpoint for registration form
        end
      end

      # Checkout
      post "checkout" => "checkout#create"
      post "checkout/embedded" => "checkout#create_embedded"
      post "checkout/confirm" => "checkout#confirm"
      get "checkout/session/:session_id" => "checkout#session_status"

      # Webhooks
      post "webhooks/stripe" => "webhooks#stripe"
    end
  end
end
