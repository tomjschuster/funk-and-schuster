defmodule FunkAndSchuster.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :title, :string
      add :caption, :text
      add :work_id, references(:work, on_delete: :nothing)
      add :artist_id, references(:artist, on_delete: :nothing)
      add :filename, :string
      add :content_type, :string

      timestamps()
    end

    create(index(:media, [:work_id]))
    create(index(:media, [:artist_id]))
  end
end
