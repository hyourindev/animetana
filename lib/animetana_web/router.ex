defmodule AnimetanaWeb.Router do
  use AnimetanaWeb, :router

  import AnimetanaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AnimetanaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :locale do
    plug AnimetanaWeb.Plugs.SetLocaleFromPath
    plug AnimetanaWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug AnimetanaWeb.ApiAuth
  end

  # Root path - redirect to locale-prefixed path based on IP
  scope "/", AnimetanaWeb do
    pipe_through :browser

    get "/", RedirectController, :to_locale
  end

  # Localized browser routes
  scope "/:locale", AnimetanaWeb do
    pipe_through [:browser, :locale]

    get "/", PageController, :home
  end

  # Localized auth routes: only accessible when NOT logged in
  scope "/:locale", AnimetanaWeb do
    pipe_through [:browser, :locale, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
    get "/auth/:provider", OAuthController, :request
    get "/auth/:provider/callback", OAuthController, :callback
  end

  # Localized auth routes: always accessible
  scope "/:locale", AnimetanaWeb do
    pipe_through [:browser, :locale]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  # Localized onboarding routes (must be logged in, but NOT have completed onboarding)
  scope "/:locale/onboarding", AnimetanaWeb do
    pipe_through [:browser, :locale, :require_authenticated_user, :redirect_if_onboarding_completed]

    get "/region", OnboardingController, :region
    post "/region", OnboardingController, :complete_region
  end

  # Localized protected browser routes (must be logged in AND have completed onboarding)
  scope "/:locale", AnimetanaWeb do
    pipe_through [:browser, :locale, :require_authenticated_user, :require_onboarding_completed]

    # Add protected routes here
  end

  # Public API routes (no locale prefix - uses user's region setting)
  scope "/api", AnimetanaWeb.Api do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
  end

  # Protected API routes
  scope "/api", AnimetanaWeb.Api do
    pipe_through :api_authenticated

    get "/auth/me", AuthController, :me
    post "/auth/onboarding", AuthController, :complete_onboarding
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:animetana, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AnimetanaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
