defmodule FunkAndSchuster.Art do
  @moduledoc """
  The Art context.
  """

  import Ecto.Query, warn: false
  alias FunkAndSchuster.Repo

  alias FunkAndSchuster.FileService
  alias FunkAndSchuster.Art.{Artist, Work, Media, Gallery}

  # Artists

  def list_artists, do: Repo.all(Artist)

  def list_artists_with_media do
    Repo.all(
      from artist in Artist,
        left_join: media in assoc(artist, :media),
        preload: [media: media]
    )
  end

  def get_artist!(id), do: Repo.get!(Artist, id)

  def get_artist_with_media!(id) do
    Repo.one!(
      from artist in Artist,
        left_join: media in assoc(artist, :media),
        where: artist.id == ^id,
        preload: [media: media]
    )
  end

  def get_artist_with_works_and_media!(id) do
    Repo.one!(
      from artist in Artist,
        left_join: media in assoc(artist, :media),
        left_join: work in assoc(artist, :works),
        left_join: work_media in assoc(work, :media),
        where: artist.id == ^id,
        preload: [media: media, works: {work, [media: work_media]}]
    )
  end

  def create_artist(attrs \\ %{}, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:artist, Artist.changeset(attrs))
    |> Ecto.Multi.run(:media, &batch_create_artist_media(files, &1.artist))
    |> Repo.transaction()
  end

  def update_artist(%Artist{} = artist, attrs, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:artist, Artist.changeset(artist, attrs))
    |> Ecto.Multi.run(:media, &batch_create_artist_media(files, &1.artist))
    |> Repo.transaction()
  end

  def change_artist(%Artist{} = artist), do: Artist.changeset(artist, %{})

  # Works
  def list_works_with_artist do
    Repo.all(
      from work in Work,
        join: artist in assoc(work, :artist),
        preload: [artist: artist]
    )
  end

  def list_works_with_artist_and_media do
    Repo.all(
      from work in Work,
        join: artist in assoc(work, :artist),
        left_join: media in assoc(work, :media),
        preload: [artist: artist, media: media]
    )
  end

  def list_artist_works_with_media(artist_id) do
    Repo.all(
      from work in Work,
        left_join: media in assoc(work, :media),
        where: [artist_id: ^artist_id],
        preload: [media: media]
    )
  end

  def get_work!(id), do: Repo.get!(Work, id)

  def get_work_with_artist!(id) do
    Repo.one!(
      from work in Work,
        join: artist in assoc(work, :artist),
        preload: [artist: artist],
        where: work.id == ^id
    )
  end

  def get_work_with_media_and_artist!(id) do
    Repo.one!(
      from work in Work,
        join: artist in assoc(work, :artist),
        left_join: media in assoc(work, :media),
        preload: [artist: artist, media: media],
        where: work.id == ^id
    )
  end

  def create_work(attrs, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:work, Work.changeset(%Work{}, attrs))
    |> Ecto.Multi.run(:media, &batch_create_work_media(files, &1.work))
    |> Repo.transaction()
  end

  def create_work_for_artist(%Artist{} = artist, attrs, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:work, Work.changeset(%Work{}, artist, attrs))
    |> Ecto.Multi.run(:media, &batch_create_work_media(files, &1.work))
    |> Repo.transaction()
  end

  def update_work(%Work{} = work, attrs, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:work, Work.changeset(work, attrs))
    |> Ecto.Multi.run(:media, &batch_create_work_media(files, &1.work))
    |> Repo.transaction()
  end

  def change_work(%Work{} = work), do: Work.changeset(work, %{})

  # Media

  def list_media, do: Repo.all(media_query())

  def list_media_for_artist(artist_id),
    do: media_query() |> where(artist_id: ^artist_id) |> Repo.all()

  def list_media_for_work(work_id),
    do: media_query() |> where(work_id: ^work_id) |> Repo.all()

  def get_media!(id), do: media_query() |> where(id: ^id) |> Repo.one!()

  defp media_query do
    from media in Media,
      left_join: work in assoc(media, :work),
      left_join: work_artist in assoc(work, :artist),
      left_join: artist in assoc(media, :artist),
      preload: [work: {work, [artist: work_artist]}, artist: artist]
  end

  defp batch_create_artist_media([], _assoc), do: {:ok, []}

  defp batch_create_artist_media(files, %Artist{} = artist) do
    files
    |> Enum.map(&create_artist_media(&1, artist))
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> case do
      %{error: errors} -> {:error, errors}
      %{ok: media} -> {:ok, media}
    end
  end

  defp batch_create_work_media([], _assoc), do: {:ok, []}

  defp batch_create_work_media(files, %Work{} = work) do
    files
    |> Enum.map(&create_work_media(&1, work))
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> case do
      %{error: errors} -> {:error, errors}
      %{ok: media} -> {:ok, media}
    end
  end

  def create_media(%FileService.FileInfo{} = file_info, attrs) do
    file_info
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  def create_artist_media(%FileService.FileInfo{} = file_info, %Artist{} = artist, attrs \\ %{}) do
    file_info
    |> Media.changeset(artist, attrs)
    |> Repo.insert()
  end

  def create_work_media(%FileService.FileInfo{} = file_info, %Work{} = work, attrs \\ %{}) do
    file_info
    |> Media.changeset(work, attrs)
    |> Repo.insert()
  end

  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  def change_media(%Media{} = media), do: Media.changeset(media, %{})

  # Galleries

  def list_galleries do
    Repo.all(gallery_query())
  end

  def get_gallery!(id), do: gallery_query() |> where(id: ^id) |> Repo.one!()

  defp gallery_query do
    from gallery in Gallery,
      left_join: gallery_media in assoc(gallery, :gallery_media),
      preload: [gallery_media: gallery_media]
  end

  def create_gallery(attrs \\ %{}) do
    %Gallery{}
    |> Gallery.changeset(attrs)
    |> Repo.insert()
  end

  def update_gallery(%Gallery{} = gallery, attrs) do
    gallery
    |> Gallery.changeset(attrs)
    |> Repo.update()
  end

  def delete_gallery(%Gallery{} = gallery) do
    Repo.delete(gallery)
  end

  def change_gallery(%Gallery{} = gallery) do
    Gallery.changeset(gallery, %{})
  end
end
