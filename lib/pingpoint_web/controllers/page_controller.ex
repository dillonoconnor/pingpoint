defmodule PingpointWeb.PageController do
  use PingpointWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def init_user(conn, _params) do
    render(conn, :init_user)
  end

  def set_user(conn, %{"username" => username}) do
    conn
    |> put_session("username", username)
    |> redirect(to: Routes.rooms_live_path(conn, :index))
  end
end
