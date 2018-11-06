defmodule FunkAndSchuster.Art do
  @moduledoc """
  The Art context.
  """

  import Ecto.Query, warn: false
  alias FunkAndSchuster.Repo

  alias FunkAndSchuster.Art
  alias FunkAndSchuster.Art.{Artist, Work, Media}

  # Artists

  def list_artists do
    Repo.all(Artist)
  end

  def get_artist!(id), do: Repo.get!(Artist, id)

  def get_artist_with_works!(id) do
    Repo.one!(
      from artist in Artist,
        left_join: work in assoc(artist, :works),
        left_join: media in assoc(work, :media),
        where: artist.id == ^id,
        preload: [works: {work, [media: media]}]
    )
  end

  def create_artist(attrs \\ %{}) do
    %Artist{}
    |> Artist.changeset(attrs)
    |> Repo.insert()
  end

  def update_artist(%Artist{} = artist, attrs) do
    artist
    |> Artist.changeset(attrs)
    |> Repo.update()
  end

  def delete_artist(%Artist{} = artist) do
    Repo.delete(artist)
  end

  def change_artist(%Artist{} = artist) do
    Artist.changeset(artist, %{})
  end

  # Works

  def list_works(%Artist{id: artist_id}) do
    Repo.all(
      from work in Work,
        left_join: media in assoc(work, :media),
        where: [artist_id: ^artist_id],
        preload: [media: media]
    )
  end

  def get_work!(id) do
    Repo.one!(
      from work in Work,
        left_join: media in assoc(work, :media),
        preload: [media: media],
        where: work.id == ^id
    )
  end

  def create_work(%Artist{} = artist, attrs, new_media) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:work, Work.changeset(%Work{}, artist, attrs))
    |> Ecto.Multi.run(:new_media, &upload_media(&1, new_media))
    |> Repo.transaction()
  end

  def update_work(%Work{} = work, attrs, deleted_media, new_media) do
    deleted_files = get_files_by_media_ids(deleted_media)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:work, Work.changeset(work, attrs))
    |> Ecto.Multi.run(:delete_files, fn _ -> delete_files(deleted_files) end)
    |> Ecto.Multi.run(:new_media, &upload_media(&1, new_media))
    |> Repo.transaction()
  end

  defp get_files_by_media_ids(media_ids) do
    Repo.all(
      from file in Art.File,
        join: media in Media,
        on: media.filename == file.filename,
        where: media.id in ^media_ids
    )
  end

  defp delete_files(deleted_files) do
    results = Enum.map(deleted_files, &delete_file!/1)
    {:ok, results}
  end

  defp upload_media(%{work: %Work{id: work_id}}, uploads) do
    media =
      uploads
      |> Stream.map(&upload_file!/1)
      |> Stream.map(&create_media!(&1, work_id))
      |> Enum.to_list()

    {:ok, media}
  end

  def delete_work(%Work{} = work) do
    Repo.delete(work)
  end

  def change_work(%Work{} = work) do
    Work.changeset(work, %{})
  end

  # Media

  def list_work_media(work_id),
    do: media_query() |> where(work_id: ^work_id) |> Repo.all()

  def list_media, do: Repo.all(media_query())

  def get_media!(id), do: media_query() |> where(id: ^id) |> Repo.one!()

  defp media_query do
    from media in Media,
      join: work in assoc(media, :work),
      join: artist in assoc(work, :artist),
      preload: [work: {work, [artist: artist]}]
  end

  def create_media!(%Art.File{} = file, work_id) do
    file
    |> Media.changeset(work_id)
    |> Repo.insert!()
  end

  def create_media(%{"file" => %Plug.Upload{} = upload, "work_id" => work_id}) do
    upload
    |> upload_file!()
    |> Media.changeset(work_id)
    |> Repo.insert!()
  end

  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  def delete_media(%Media{} = media), do: Repo.delete(media)

  def change_media(%Media{} = media), do: Media.changeset(media, %{})

  # File

  def upload_file!(%Plug.Upload{} = upload) do
    upload
    |> Art.File.changeset()
    |> Repo.insert!()
  end

  def delete_file!(%Art.File{} = file), do: Repo.delete!(file)
end
