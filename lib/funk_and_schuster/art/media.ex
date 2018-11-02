defmodule FunkAndSchuster.Art.Media do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias FunkAndSchuster.Art

  schema "media" do
    field :title, :string
    field :work_id, :integer
    field :filename, :string
    field :content_type, :string
    field :deleted?, :boolean, virtual: true, default: false

    timestamps()
  end

  @doc false
  def changeset(%Media{} = media, attrs) when is_map(attrs) do
    IO.inspect({media, attrs}, label: "CHANGING!!!!!!!!!!!!!!!!!!!!!")

    media
    |> cast(attrs, [:title, :deleted?])
    |> IO.inspect()
    |> maybe_mark_for_deletion()
  end

  def changeset(%Art.File{} = file, work_id) when is_integer(work_id) do
    attrs = %{
      title: title_from_filename(file.filename),
      work_id: work_id,
      filename: file.filename,
      content_type: file.content_type
    }

    %Media{}
    |> cast(attrs, [:title, :work_id, :filename, :content_type])
    |> validate_required([:title, :work_id, :filename, :content_type])
  end

  defp maybe_mark_for_deletion(changeset) do
    IO.inspect(get_change(changeset, :delete?), label: "MAYBE MARK FOR DELETION")

    if get_change(changeset, :deleted?) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end

  defp title_from_filename(<<_hash::size(64), filename::binary>>) do
    filename
    |> remove_extension()
    |> title_case()
  end

  defp title_from_filename(filename) when is_binary(filename) do
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
