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
  resources :messages, only: [ :create ]
  resources :questionnaire_submissions, only: [ :new, :create ], path: "client-questionnaire"
  get "trade-network", to: "pages#trade_network"

  # Authenticated client portal (real, data-driven)
  namespace :client do
    resources :projects, only: [ :index, :show ] do
      resources :quotes, only: [ :show ] do
        member do
          post :approve
        end
        resources :quote_line_items, only: [] do
          member do
            post :approve, action: :approve_line_item
            post :decline, action: :decline_line_item
          end
        end
      end
    end
  end

  # Tech/installer portal
  namespace :tech do
    root "dashboard#show"
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
      resources :rooms do
        resources :windows
      end
      resources :quotes do
        member do
          post :send_quote
          get :preview
          post :save_as_template
        end
        resources :quote_line_items, only: [ :new, :create, :edit, :update, :destroy ]
      end
      resources :design_presentations do
        resource :publication, only: [ :create, :destroy ]
        resources :mood_boards do
          member do
            patch :move
          end
          resources :mood_board_items do
            member do
              patch :move
            end
          end
        end
        resources :product_selections do
          member do
            patch :move
          end
        end
        resources :color_swatches do
          member do
            patch :move
          end
        end
      end
    end
    resources :messages, only: [ :index, :show, :destroy ]
    resources :questionnaire_submissions, only: [ :index, :show, :destroy ]
    resources :trade_partners
    resources :services
    resources :checklist_items
    resources :manufacturers
    resources :product_categories
    resources :products do
      get :search, on: :collection
    end
    resources :swatches
    resources :promo_codes
    resource :settings, only: [] do
      get :margins, on: :member
    end
    get "templates", to: "quotes#templates", as: :quote_templates
    post "templates/load", to: "quotes#load", as: :load_quote_templates
    resources :purchase_orders do
      member do
        post :submit
        post :confirm_delivery
        post :mark_shipped
        post :mark_received
      end
    end
  end

  # Public "client-portal" link routes into the authenticated portal.
  # Devise redirects to sign-in if not logged in.
  get "client-portal", to: redirect("/client/projects")

  # Tech portal shortcut
  get "installer", to: redirect("/tech")
end
