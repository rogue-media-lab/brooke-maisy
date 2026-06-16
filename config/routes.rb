Rails.application.routes.draw do
  # Invitation-only: registration disabled. Clients are created by an admin.
  devise_for :users, skip: [ :registrations ]
  # Error pages
  match "/404", to: "errors#not_found",             via: :all
  match "/422", to: "errors#unprocessable_entity",  via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Page routes
  get "/", to: "pages#home", as: :root
  get "about", to: "pages#about"
  get "services", to: "pages#services"
  get "portfolio", to: "pages#portfolio"
  get "contact", to: "pages#contact"
  get "trade-network", to: "pages#trade_network"

  # Authenticated client portal (real, data-driven)
  namespace :client do
    resources :projects, only: [ :index, :show ]
  end

  # Admin area — Brooke manages clients, projects, and updates.
  namespace :admin do
    root "dashboard#index"
    resources :clients do
      member do
        post :resend_invite
      end
    end
    resources :projects do
      resources :project_updates, only: [ :create, :destroy ]
    end
  end

  # Public "client-portal" link routes into the authenticated portal.
  # Devise redirects to sign-in if not logged in.
  get "client-portal", to: redirect("/client/projects")
end
