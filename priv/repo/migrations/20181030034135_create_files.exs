defmodule FunkAndSchuster.Repo.Migrations.CreateFiles do
  use Ecto.Migration

  def change do
    create table(:files) do
      add :filename, :string
      add :content_type, :string
      add :data, :binary

      timestamps()
    end

  end
end
