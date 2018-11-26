defmodule FunkAndSchuster.Art.Gallery do
  use Ecto.Schema
  import Ecto.Changeset

  alias FunkAndSchuster.Art.GalleryMedia

  schema "gallery" do
    field :title, :string
    has_many :gallery_media, GalleryMedia

    timestamps()
  end

  @doc false
  def changeset(gallery, attrs) do
    IO.inspect(attrs)

    gallery
    |> cast(attrs, [:title])
    |> cast_assoc(:gallery_media)
    |> IO.inspect()
    |> validate_required([:title])
  end
end
