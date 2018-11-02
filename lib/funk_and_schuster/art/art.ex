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
    Repo.all(from Work, where: [artist_id: ^artist_id])
  end

  def get_work!(id), do: Repo.get!(Work, id)

  def create_work(%Artist{} = artist, attrs \\ %{}, media \\ []) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:work, Work.changeset(%Work{}, artist, attrs))
    |> Ecto.Multi.run(:media, Art, :upload_media, [media])
    |> Repo.transaction()
  end

  def update_work(%Work{} = work, attrs \\ %{}, media \\ []) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:work, Work.changeset(work, attrs))
    |> Ecto.Multi.run(:media, Art, :upload_media, [media])
    |> Repo.transaction()
  end

  def upload_media(%{work: %Work{id: work_id}}, uploads) do
    media =
      uploads
      |> Stream.each(&upload_file!/1)
      |> Enum.map(&create_media!(&1, work_id))

    {:ok, media}
  end

  def delete_work(%Work{} = work) do
    Repo.delete(work)
  end

  def change_work(%Work{} = work) do
    Work.changeset(work, %{})
  end

  # Media

  def create_media!(%Plug.Upload{} = upload, work_id) do
    upload
    |> Media.changeset(work_id)
    |> Repo.insert!()
  end

  def list_media(work_id) do
    Repo.all(from Media, where: [work_id: ^work_id])
  end

  def get_media(filename) when is_binary(filename) do
    Repo.get_by(Art.File, filename: filename)
  end

  # File

  def upload_file!(%Plug.Upload{} = upload) do
    upload
    |> Art.File.changeset()
    |> Repo.insert!()
  end
end
