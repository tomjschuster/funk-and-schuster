defmodule FunkAndSchuster.Art.GalleryMedia do
  use Ecto.Schema
  import Ecto.Changeset


  schema "gallery_media" do
    field :gallery_id, :id
    field :media_id, :id

    timestamps()
  end

  @doc false
  def changeset(gallery_media, attrs) do
    gallery_media
    |> cast(attrs, [])
    |> validate_required([])
  end
end
