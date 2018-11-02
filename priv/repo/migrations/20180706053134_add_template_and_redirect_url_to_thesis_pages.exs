defmodule FunkAndSchuster.Repo.Migrations.AddTemplateAndRedirectUrlToThesisPages do
  @moduledoc false
  use Ecto.Migration

  def up do
    alter table(:thesis_pages) do
      add :template, :string
      add :redirect_url, :string
    end
  end

  def down do
    alter table(:thesis_pages) do
      remove(:template)
      remove(:redirect_url)
    end
  end
end
