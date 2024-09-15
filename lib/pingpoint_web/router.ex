defmodule PingpointWeb.Router do
  use PingpointWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PingpointWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PingpointWeb do
    pipe_through :browser

    get "/", PageController, :home
    post "/set_user", SessionController, :set_user

    live "/retro", RetroLive.Show
    live "/rooms", RoomLive.Show, :show
    live "/rooms/:id/edit", RoomLive.Index, :edit

    live "/rooms/:id", RoomLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", PingpointWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pingpoint, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PingpointWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
