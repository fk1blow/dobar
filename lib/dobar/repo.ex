defmodule Dobar.Repo do
  use Ecto.Repo,
    otp_app: :dobar,
    adapter: Ecto.Adapters.Postgres
end
