defmodule BankingApiWeb.Router do
  use BankingApiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser_auth do
    plug BankingApiWeb.Auth.Pipeline
  end

  pipeline :ensure_authenticated do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :api_auth do
    plug BankingApiWeb.Api.Auth.Pipeline
  end

  scope "/", BankingApiWeb do
    pipe_through [:browser, :browser_auth]

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  scope "/", BankingApiWeb do
    pipe_through [:browser, :browser_auth, :ensure_authenticated]

    get "/", BackOfficeController, :index
    put "/export", BackOfficeController, :export
  end

  scope "/api/v1", BankingApiWeb.Api.V1 do
    pipe_through :api

    post "/users/signup", UserController, :create
    post "/users/signin", UserController, :signin
  end

  scope "/api/v1", BankingApiWeb.Api.V1 do
    pipe_through [:api, :api_auth]

    resources "/withdraws", WithdrawController, only: [:create]
    resources "/transfers", TransferController, only: [:create]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    forward "/sent_emails", Bamboo.SentEmailViewerPlug

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: BankingApiWeb.Telemetry
    end
  end
end
