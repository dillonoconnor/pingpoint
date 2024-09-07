defmodule PingpointWeb.SessionController do
  use PingpointWeb, :controller

  def set_user(conn, %{"username" => username, "avatar" => avatar}) do
    conn
    |> put_session("username", username)
    |> put_session("avatar", avatar)
    |> redirect(to: ~p"/rooms")
  end
end
