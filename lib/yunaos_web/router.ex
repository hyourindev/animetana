defmodule YunaosWeb.Router do
  use YunaosWeb, :router

  import YunaosWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YunaosWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug YunaosWeb.ApiAuth
  end

  # Public browser routes
  scope "/", YunaosWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Auth routes: only accessible when NOT logged in
  scope "/", YunaosWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

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

  # Auth routes: always accessible
  scope "/", YunaosWeb do
    pipe_through :browser

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  # Protected browser routes (must be logged in)
  scope "/", YunaosWeb do
    pipe_through [:browser, :require_authenticated_user]
  end

  # Public API routes
  scope "/api", YunaosWeb.Api do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
  end

  # Protected API routes
  scope "/api", YunaosWeb.Api do
    pipe_through :api_authenticated
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:yunaos, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: YunaosWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
