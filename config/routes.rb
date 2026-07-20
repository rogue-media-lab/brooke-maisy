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
  namespace :clients do
    resources :projects, only: [ :index, :show ]
    resources :quotes, only: [ :show ] do
      member do
        post :approve
      end
      resources :quote_line_items, only: [], controller: "quotes" do
        member do
          post :approve, action: :approve_line_item
          post :decline, action: :decline_line_item
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
        post :invite
        post :resend_invite
      end
      collection do
        get :selector
      end
    end
    resources :projects do
      resources :project_updates, only: [ :create, :destroy ]
      resources :rooms do
        resources :windows
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
      get :swatches, on: :member
    end
    resources :swatches
    resources :promo_codes
    resource :settings, only: [] do
      get :margins, on: :member
    end
    get "templates", to: "quotes#templates", as: :quote_templates
    post "templates/load", to: "quotes#load", as: :load_quote_templates
    resources :quotes do
      member do
        post :send_quote
        get :preview
        post :save_as_template
        post :convert_to_project
        get :measurements, to: "quote_measurements#show"
        post :create_room, to: "quote_measurements#create_room"
        post :create_window, to: "quote_measurements#create_window"
        delete :destroy_window, to: "quote_measurements#destroy_window"
        post :create_photo, to: "quote_measurements#create_photo"
        delete :destroy_photo, to: "quote_measurements#destroy_photo"
        get :payment, to: "quote_payments#show"
        post :payment, to: "quote_payments#create"
        delete :destroy_payment, to: "quote_payments#destroy"
        resource :documents, only: [ :show ], controller: "quote_documents" do
          get :sign
          get :sign_designer
          post :create_signature
          get ":form/download", to: "quote_documents#download", as: :download
        end
      end
      resources :quote_line_items, only: [ :new, :create, :edit, :update, :destroy ]
    end
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
  get "client-portal", to: redirect("/clients/projects")

  # Tech portal shortcut
  get "installer", to: redirect("/tech")
end
