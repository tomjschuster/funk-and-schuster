defmodule FunkAndSchuster.Repo.Migrations.CreateArtist do
  use Ecto.Migration

  def change do
    create table(:artist) do
      add :first_name, :string
      add :last_name, :string
      add :dob, :date

      timestamps()
    end
  end
end
