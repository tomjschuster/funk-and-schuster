defmodule FunkAndSchuster.Art.Artist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "artists" do
    field :first_name, :string
    field :last_name, :string
    field :dob, :date

    timestamps()
  end

  @doc false
  def changeset(artist, attrs) do
    artist
    |> cast(attrs, [:first_name, :last_name, :dob])
    |> validate_required([:first_name, :last_name, :dob])
  end
end