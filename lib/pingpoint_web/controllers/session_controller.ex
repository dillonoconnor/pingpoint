defmodule PingpointWeb.SessionController do
  use PingpointWeb, :controller

  def set_user(conn, %{"username" => username}) do
    conn
    |> put_session("username", username)
    |> redirect(to: ~p"/rooms")
  end
end
