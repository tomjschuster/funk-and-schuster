defmodule FunkAndSchuster.Repo.Migrations.CreateWork do
  use Ecto.Migration

  def change do
    create table(:work) do
      add :title, :string
      add :date, :date
      add :medium, :string
      add :dimensions, :string
      add :artist_id, references(:artist, on_delete: :nothing)

      timestamps()
    end

    create(index(:work, [:artist_id]))
  end
end
