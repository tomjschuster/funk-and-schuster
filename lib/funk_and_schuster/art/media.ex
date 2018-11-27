defmodule FunkAndSchuster.Art.Media do
  use Ecto.Schema
  import Ecto.Changeset
  alias FunkAndSchuster.FileService
  alias FunkAndSchuster.Art.{Media, Work, Artist}

  schema "media" do
    field :title, :string
    field :caption, :string
    field :filename, :string
    field :content_type, :string
    field :deleted?, :boolean, virtual: true, default: false
    field :assoc_type, :string, virtual: true
    field :file, :binary, virtual: true

    belongs_to :work, Work
    belongs_to :artist, Artist

    timestamps()
  end

  def changeset(attrs) when is_map(attrs) do
    %Media{}
    |> cast(attrs, [:title, :caption, :assoc_type, :work_id, :artist_id, :deleted?])
    |> cast_assoc_type()
    |> validate_required([:title])
  end

  def changeset(%Media{} = media, attrs) when is_map(attrs) do
    media
    |> cast(attrs, [:title, :caption, :assoc_type, :work_id, :artist_id, :deleted?])
    |> cast_assoc_type()
    |> maybe_mark_for_deletion()
    |> validate_required([:title])
  end

  def changeset(%FileService.FileInfo{} = file_info, attrs) when is_map(attrs) do
    %Media{}
    |> cast(attrs, [:title, :caption, :assoc_type, :work_id, :artist_id])
    |> cast_assoc_type()
    |> put_change(:filename, file_info.filename)
    |> put_change(:content_type, file_info.content_type)
    |> validate_required([:title, :filename, :content_type])
  end

  def changeset(%FileService.FileInfo{} = file_info, %Work{} = work, attrs) when is_map(attrs) do
    %Media{}
    |> change()
    |> put_change(:title, work.title)
    |> cast(attrs, [:title, :caption, :deleted?])
    |> put_assoc(:work, work)
    |> put_change(:filename, file_info.filename)
    |> put_change(:content_type, file_info.content_type)
    |> validate_required([:title, :filename, :content_type])
  end

  def changeset(%FileService.FileInfo{} = file_info, %Artist{} = artist, attrs)
      when is_map(attrs) do
    %Media{}
    |> change()
    |> put_change(:title, artist.first_name <> " " <> artist.last_name)
    |> cast(attrs, [:title, :caption, :deleted?])
    |> put_assoc(:artist, artist)
    |> put_change(:filename, file_info.filename)
    |> put_change(:content_type, file_info.content_type)
    |> validate_required([:title, :filename, :content_type])
  end

  def no_file_changeset(attrs) do
    {:error, changeset} =
      attrs
      |> changeset
      |> validate_required([:title])
      |> add_error(:file, "can't be blank")
      |> apply_action(:insert)

    changeset
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
end
