require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "authentication#login"
      post "auth/verify_otp", to: "authentication#verify_otp"

      # Users routes
      resources :users, only: [] do
        collection do
          post "update_name"
        end
      end

      # Properties routes
      resources :properties, only: [ :index, :show ]

      # Lease Agreements Routes (mapped to LeaseAgreementsController)
      get "leases/:property_id", to: "lease_agreements#index", as: "lease_agreements"
      get "leases/:property_id/:id", to: "lease_agreements#show", as: "lease_agreement"

      # Rent routes
      post "rent/pay", to: "rents#pay"
      get "rents", to: "rents#index"
    end
  end


  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self) do
    resources :properties do
      resources :units do
        member do
          put :deactivate_tenant
        end

        resources :tenants do
          collection do
            get :new
            post :create
          end
        end
      end
    end
  end

  # Health check route
  get "up", to: "rails/health#show", as: :rails_health_check

  # PWA-related routes
  get "service-worker", to: "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest
end
