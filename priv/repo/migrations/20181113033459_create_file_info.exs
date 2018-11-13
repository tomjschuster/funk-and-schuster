defmodule FunkAndSchuster.Repo.Migrations.CreateFileInfo do
  use Ecto.Migration

  def change do
    create table(:file_info) do
      add :filename, :string
      add :content_type, :string
      add :data, :binary

      timestamps()
    end
  end
end
