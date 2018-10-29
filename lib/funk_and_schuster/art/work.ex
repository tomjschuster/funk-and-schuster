defmodule FunkAndSchuster.Art.Work do
  use Ecto.Schema
  import Ecto.Changeset

  alias FunkAndSchuster.Art.Artist

  schema "works" do
    field :date, :date
    field :dimensions, :string
    field :medium, :string
    field :title, :string
    belongs_to :artist, Artist

    timestamps()
  end

  @doc false
  def changeset(work, artist, attrs) do
    work
    |> cast(attrs, [:title, :medium, :dimensions, :date])
    |> validate_required([:title, :medium, :dimensions, :date])
    |> put_assoc(:artist, artist)
  end
end
