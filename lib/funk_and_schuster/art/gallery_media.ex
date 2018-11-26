defmodule FunkAndSchuster.Art.GalleryMedia do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gallery_media" do
    field :gallery_id, :id
    field :media_id, :id
    field :checked?, :boolean, virtual: true

    timestamps()
  end

  @doc false
  def changeset(gallery_media, attrs) do
    gallery_media
    |> cast(attrs, [:gallery_id, :media_id, :checked?])
    |> mark_action()
    |> IO.inspect()
  end

  defp mark_action(changeset) do
    id = get_field(changeset, :id)
    checked? = get_change(changeset, :checked?)

    c =
      case {id, checked?} do
        {nil, true} -> %{changeset | action: :insert}
        {nil, false} -> %{changeset | action: :ignore}
        {^id, true} -> %{changeset | action: :update}
        {^id, false} -> %{changeset | action: :delete}
      end

    IO.inspect({id, checked?, c})

    c
  end
end
