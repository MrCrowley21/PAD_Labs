defmodule GatewayWebService.Router do
  use GatewayWeb, :router

  pipeline :health do
    plug :accepts, ["json"]
  end

  scope "/health", GatewayWeb do
    pipe_through :health

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", GatewayWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  # if Application.compile_env(:gateway, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    # import Phoenix.LiveDashboard.Router

    # scope "/dev" do
    #   pipe_through :browser

    #   live_dashboard "/dashboard", metrics: GatewayWeb.Telemetry
    #   forward "/mailbox", Plug.Swoosh.MailboxPreview
    # end
  # end
end