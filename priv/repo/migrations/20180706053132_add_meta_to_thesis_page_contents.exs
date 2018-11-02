defmodule FunkAndSchuster.Repo.Migrations.AddMetaToThesisPageContents do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:thesis_page_contents) do
      add :meta, :text
    end
  end

  def down do
    alter table(:thesis_page_contents) do
      remove(:meta)
    end
  end
end
