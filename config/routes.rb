# AI-assisted — prompt: "Implement Google OAuth with Devise + OmniAuth per CSCE 431 primer"; added Google callbacks, session routes and Books home while preserving CRUD.
Rails.application.routes.draw do
  root "books#index"
  devise_for :admins, controllers: { omniauth_callbacks: "admins/omniauth_callbacks" }
  devise_scope :admin do
    get "admins/sign_in", to: "admins/sessions#new", as: :new_admin_session
    get "admins/sign_out", to: "admins/sessions#destroy", as: :destroy_admin_session
  end

  # AI-assisted (OpenAI/agent), 9/14/26 — prompt: "add a resourceful book delete confirmation page".
  resources :books do
    member { get :delete }
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
