defmodule FunkAndSchuster.Repo.Migrations.CreateWorks do
  use Ecto.Migration

  def change do
    create table(:works) do
      add :title, :string
      add :date, :date
      add :medium, :string
      add :dimensions, :string
      add :artist_id, references(:artists, on_delete: :nothing)

      timestamps()
    end

    create(index(:works, [:artist_id]))
  end
end
