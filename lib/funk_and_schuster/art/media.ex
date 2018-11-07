defmodule FunkAndSchuster.Art.Media do
  use Ecto.Schema
  import Ecto.Changeset
  alias FunkAndSchuster.Art
  alias FunkAndSchuster.Art.{Media, Work, Artist}

  schema "media" do
    field :title, :string
    field :filename, :string
    field :content_type, :string
    field :deleted?, :boolean, virtual: true, default: false
    field :assoc_type, :string, virtual: true

    belongs_to :work, Work
    belongs_to :artist, Artist

    timestamps()
  end

  @doc false
  def changeset(%Media{} = media, attrs) when is_map(attrs) do
    media
    |> cast(attrs, [:title, :assoc_type, :work_id, :artist_id, :deleted?])
    |> cast_assoc_type()
    |> validate_required([:title])
    |> maybe_mark_for_deletion()
  end

  def changeset(%Art.File{} = file, attrs) do
    file_attrs = %{
      title: Map.get(attrs, :title, title_from_filename(file.filename)),
      filename: file.filename,
      content_type: file.content_type
    }

    %Media{}
    |> cast(attrs, [:title, :work_id, :artist_id])
    |> cast(file_attrs, [:title, :filename, :content_type])
    |> validate_required([:title, :filename, :content_type])
  end

  def changeset(nil, attrs) do
    %Media{}
    |> cast(attrs, [:title, :work_id, :artist_id])
    |> add_error(:file, "can't be blank")
    |> validate_required([:title])
  end

  defp cast_assoc_type(changeset) do
    case get_field(changeset, :assoc_type) do
      nil ->
        infer_assoc_type(changeset)

      "work" ->
        put_change(changeset, :artist_id, nil)

      "artist" ->
        put_change(changeset, :work_id, nil)

      "none" ->
        cast(changeset, %{work_id: nil, artist_id: nil}, [:work_id, :artist_id])
    end
  end

  defp infer_assoc_type(changeset) do
    work_id = get_field(changeset, :work_id)
    artist_id = get_field(changeset, :artist_id)

    case {work_id, artist_id} do
      {nil, nil} -> put_change(changeset, :assoc_type, "none")
      {_, nil} -> put_change(changeset, :assoc_type, "work")
      {nil, _} -> put_change(changeset, :assoc_type, "artist")
    end
  end

  defp maybe_mark_for_deletion(changeset) do
    if get_change(changeset, :deleted?) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end

  # 8 chars + dash
  @hash_size 72
  defp title_from_filename(<<_hash::size(@hash_size), filename::binary>>) do
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
    |> Enum.join(".")
  end

  defp title_case(string) do
    string
    |> Recase.to_snake()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
