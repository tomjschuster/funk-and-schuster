defmodule FunkAndSchuster.Art.Media do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "media" do
    field :title, :string
    field :work_id, :integer
    field :filename, :string
    field :content_type, :string
    timestamps()
  end

  @doc false
  def changeset(%Plug.Upload{} = upload, work_id) when is_integer(work_id) do
    attrs = %{
      title: title_from_filename(upload.filename),
      work_id: work_id,
      filename: upload.filename,
      content_type: upload.content_type
    }

    %Media{}
    |> cast(attrs, [:title, :work_id, :filename, :content_type])
    |> validate_required([:title, :work_id, :filename, :content_type])
  end

  defp title_from_filename(filename) do
    filename
    |> remove_extension()
    |> title_case()
  end

  defp remove_extension(filename) do
    filename
    |> String.split(".")
    |> Enum.reverse()
    |> case do
      [_extenstion, first | rest] -> [first | rest]
      parts -> parts
    end
    |> Enum.reverse()
    |> Enum.join("_")
  end

  defp title_case(string) do
    string
    |> Recase.to_snake()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
