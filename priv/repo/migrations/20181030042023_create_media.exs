defmodule FunkAndSchuster.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :title, :string
      add :work_id, references(:works, on_delete: :nothing)
      add :file_id, references(:files, on_delete: :nothing)

      timestamps()
    end

    create(index(:media, [:work_id]))
    create(index(:media, [:file_id]))
  end
end
