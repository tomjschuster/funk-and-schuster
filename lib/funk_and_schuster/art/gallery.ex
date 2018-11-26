defmodule FunkAndSchuster.Art.Gallery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gallery" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(gallery, attrs) do
    gallery
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
