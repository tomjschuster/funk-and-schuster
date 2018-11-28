defmodule FunkAndSchuster.Repo.Migrations.FeaturedGallery do
  use Ecto.Migration

  def up do
    alter table(:gallery) do
      add :featured, :boolean, null: false, default: false
    end
  end

  def down do
    drop :featured
  end
end
