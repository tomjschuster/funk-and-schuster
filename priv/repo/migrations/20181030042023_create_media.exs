defmodule FunkAndSchuster.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :title, :string
      add :work_id, references(:works, on_delete: :nothing)
      add :artist_id, references(:artists, on_delete: :nothing)
      add :filename, :string
      add :content_type, :string

      timestamps()
    end

    create(index(:media, [:work_id]))
  end
end
