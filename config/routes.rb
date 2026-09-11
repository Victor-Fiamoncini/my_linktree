Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Machine-facing / locale-independent endpoints — deliberately not locale-scoped.
  get "sitemap.xml" => "static#sitemap"
  get "AGENTS.md" => "static#agents_md"
  get "llms.txt" => "static#agents_md"
  post "contact" => "contacts#create"

  namespace :api do
    get "telemetry" => "telemetry#index"
    post "hire" => "hire#create"
    match "mcp" => "mcp#create", via: [ :post, :get, :options, :delete ]
  end

  # Bare "/" has no canonical locale of its own — English is the default language
  # for every visitor; switching to pt-BR is an explicit choice via the header
  # language switcher, never auto-detected from the browser.
  get "/", to: redirect("/en", status: 302)

  scope "/:locale", constraints: { locale: /en|pt-BR/ } do
    root "pages#home"
    get "telemetry" => "telemetry_page#show"
  end
end
