defmodule FunkAndSchuster.ArtApi do
  @moduledoc """
  The Art context.
  """

  import Ecto.Query, warn: false
  alias FunkAndSchuster.Repo

  alias FunkAndSchuster.FileService
  alias FunkAndSchuster.Art.{Artist, Work, Media}
  # Artists

  def list_artists, do: Repo.all(Artist)

  def get_artist!(id), do: Repo.get!(Artist, id)

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
  def list_works, do: Repo.all(Work)

  def get_work!(id), do: Repo.get!(Work, id)

  def create_work(attrs, files) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:work, Work.changeset(%Work{}, attrs))
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
  Medi
  def list_media, do: Repo.all(Media)

  def get_media!(id), do: Repo.get!(Media, id)

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

  def change_media(%Media{} = media), do: Media.changeset(media, %{})

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
end
