defmodule FunkAndSchuster.Art.Gallery do
  use Ecto.Schema
  import Ecto.Changeset

  alias FunkAndSchuster.Art.GalleryMedia

  schema "gallery" do
    field :title, :string
    field :featured, :boolean, default: false
    has_many :gallery_media, GalleryMedia

    timestamps()
  end

  @doc false
  def changeset(gallery, attrs) do
    gallery
    |> cast(attrs, [:title])
    |> cast_assoc(:gallery_media)
    |> validate_required([:title])
  end

  def featured_changeset(gallery) do
    gallery
    |> change()
    |> put_change(:featured, true)
  end
end
