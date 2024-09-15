defmodule PingpointWeb.SessionController do
  use PingpointWeb, :controller

  def set_user(conn, %{"username" => username, "avatar" => avatar}) do
    conn
    |> put_session("username", username)
    |> put_session("avatar", avatar)
    |> redirect(to: get_referrer(conn))
  end

  defp get_referrer(conn) do
    case get_req_header(conn, "referer") do
      [referrer] -> URI.parse(referrer).path
      # or some default URL
      _ -> "/"
    end
  end
end
