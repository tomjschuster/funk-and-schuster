defmodule FunkAndSchuster.Art.File do
  use Ecto.Schema
  import Ecto.Changeset
  alias FunkAndSchuster.Art

  schema "files" do
    field :filename, :string
    field :content_type, :string
    field :data, :binary

    timestamps()
  end

  def changeset(%Plug.Upload{} = upload) do
    %Art.File{}
    |> cast(%{filename: upload.filename}, [:filename])
    |> cast(%{data: File.read!(upload.path)}, [:data])
    |> cast(%{content_type: upload.content_type}, [:content_type])
    |> validate_required([:content_type, :filename, :data])
  end
end