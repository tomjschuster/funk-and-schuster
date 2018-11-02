defmodule FunkAndSchuster.Art.Media do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "media" do
    field :title, :string
    field :work_id, :integer
    field :file_id, :integer
    field :filename, :string, virtual: true
    timestamps()
  end

  @doc false
  def changeset(filename, work_id, file_id)
      when is_binary(filename) and is_integer(work_id) and is_integer(file_id) do
    attrs = %{
      title: title_from_filename(filename),
      work_id: work_id,
      file_id: file_id
    }

    %Media{}
    |> cast(attrs, [:title, :work_id, :file_id])
    |> validate_required([:title, :work_id, :file_id])
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
