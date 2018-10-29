defmodule FunkAndSchuster.Repo.Migrations.CreateArtists do
  use Ecto.Migration

  def change do
    create table(:artists) do
      add :first_name, :string
      add :last_name, :string
      add :dob, :date

      timestamps()
    end

  end
end
