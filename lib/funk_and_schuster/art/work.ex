defmodule FunkAndSchuster.Art.Work do
  use Ecto.Schema
  import Ecto.Changeset

  alias FunkAndSchuster.Art.{Work, Artist, Media}

  schema "works" do
    field :title, :string
    field :date, :date
    field :medium, :string
    field :dimensions, :string

    has_many :media, Media
    belongs_to :artist, Artist

    timestamps()
  end

  @doc false
  def changeset(%Work{} = work, %{} = attrs) do
    work
    |> cast(attrs, [:title, :date, :medium, :dimensions])
    |> cast_assoc(:media)
    |> validate_required([:title, :date, :medium, :dimensions])
  end

  def changeset(%Work{} = work, %Artist{} = artist, %{} = attrs) do
    work
    |> cast(attrs, [:title, :date, :medium, :dimensions])
    |> put_assoc(:artist, artist)
    |> cast_assoc(:media)
    |> validate_required([:title, :date, :medium, :dimensions, :artist])
  end
end
