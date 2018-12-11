defmodule FunkAndSchuster.Repo do
  use Ecto.Repo,
    otp_app: :funk_and_schuster,
    adapter: Ecto.Adapters.Postgres
end
