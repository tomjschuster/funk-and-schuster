defmodule FunkAndSchuster.Art do
  @moduledoc """
  The Art context.
  """

  import Ecto.Query, warn: false
  alias FunkAndSchuster.Repo

  alias FunkAndSchuster.FileService
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

  def list_works_with_artist do
    Repo.all(
      from work in Work,
        join: artist in assoc(work, :artist),
        preload: [artist: artist]
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

  def create_work(%Artist{} = artist, attrs, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:work, Work.changeset(%Work{}, artist, attrs))
    |> Ecto.Multi.run(:media, &create_media_from_files(files, &1.work))
    |> Repo.transaction()
  end

  def update_work(%Work{} = work, attrs, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:work, Work.changeset(work, attrs))
    |> Ecto.Multi.run(:media, &create_media_from_files(files, &1.work))
    |> Repo.transaction()
  end

  defp create_media_from_files([], _assoc), do: {:ok, []}

  defp create_media_from_files(files, assoc) do
    files
    |> Enum.map(&create_media(&1, assoc))
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> case do
      %{error: errors} -> {:error, errors}
      %{ok: media} -> {:ok, media}
    end
  end

  def delete_work(%Work{} = work) do
    Repo.delete(work)
  end

  def change_work(%Work{} = work) do
    Work.changeset(work, %{})
  end

  # Media

  def list_media, do: Repo.all(media_query())

  def list_work_media(work_id),
    do: media_query() |> where(work_id: ^work_id) |> Repo.all()

  def get_media!(id), do: media_query() |> where(id: ^id) |> Repo.one!()

  defp media_query do
    from media in Media,
      left_join: work in assoc(media, :work),
      left_join: work_artist in assoc(work, :artist),
      left_join: artist in assoc(media, :artist),
      preload: [work: {work, [artist: work_artist]}, artist: artist]
  end

  def create_media(%FileService.FileInfo{} = file_info, attrs) do
    file_info
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  def delete_media(%Media{} = media), do: Repo.delete(media)

  def change_media(%Media{} = media), do: Media.changeset(media, %{})
end
