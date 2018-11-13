defmodule FunkAndSchuster.FileService.FileInfo do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "file_info" do
    field :filename, :string
    field :content_type, :string
    field :data, :binary

    timestamps()
  end

  def changeset(%Plug.Upload{} = upload) do
    %FileInfo{}
    |> change()
    |> put_change(:filename, random_string() <> "-" <> upload.filename)
    |> put_change(:data, File.read!(upload.path))
    |> put_change(:content_type, upload.content_type)
    |> validate_required([:content_type, :filename, :data])
  end

  @hash_size 8
  def random_string do
    @hash_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @hash_size)
  end
end
