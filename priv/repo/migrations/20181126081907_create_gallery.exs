defmodule FunkAndSchuster.Repo.Migrations.CreateGallery do
  use Ecto.Migration

  def change do
    create table(:gallery) do
      add :title, :string

      timestamps()
    end
  end
end
