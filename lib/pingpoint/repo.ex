defmodule Pingpoint.Repo do
  use Ecto.Repo,
    otp_app: :pingpoint,
    adapter: Ecto.Adapters.Postgres
end
