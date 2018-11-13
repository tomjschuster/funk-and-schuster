defmodule FunkAndSchuster.Art.Artist do
  use Ecto.Schema
  import Ecto.Changeset
  alias FunkAndSchuster.Art.{Work, Media}

  schema "artist" do
    field :first_name, :string
    field :last_name, :string
    field :dob, :date

    has_many :works, Work
    has_many :media, Media

    timestamps()
  end

  @doc false
  def changeset(artist, attrs) do
    artist
    |> cast(attrs, [:first_name, :last_name, :dob])
    |> cast_assoc(:media)
    |> validate_required([:first_name, :last_name, :dob])
  end
end
