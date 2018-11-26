defmodule FunkAndSchuster.Repo.Migrations.CreateGalleryMedia do
  use Ecto.Migration

  def change do
    create table(:gallery_media) do
      add :gallery_id, references(:gallery, on_delete: :nothing)
      add :media_id, references(:media, on_delete: :nothing)

      timestamps()
    end

    create(index(:gallery_media, [:gallery_id]))
    create(index(:gallery_media, [:media_id]))
  end
end
