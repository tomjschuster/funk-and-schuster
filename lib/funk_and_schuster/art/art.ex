defmodule FunkAndSchuster.Art do
  @moduledoc """
  The Art context.
  """

  import Ecto.Query, warn: false
  alias FunkAndSchuster.Repo

  alias FunkAndSchuster.Art
  alias FunkAndSchuster.Art.{Artist, Work, Media}

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

  def list_works(%Artist{id: artist_id}) do
    Repo.all(from Work, where: [artist_id: ^artist_id])
  end

  def get_work!(id), do: Repo.get!(Work, id)

  def create_work(%Artist{} = artist, attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:work, Work.changeset(%Work{}, artist, attrs))
    |> Ecto.Multi.run(:media, fn %{work: %Work{id: work_id}} ->
      media =
        attrs
        |> Map.get("media", [])
        |> Enum.map(fn %Plug.Upload{} = upload ->
          file = create_file!(upload)
          create_media!(file.filename, work_id, file.id)
        end)

      {:ok, media}
    end)
    |> Repo.transaction()
  end

  def update_work(%Work{} = work, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:work, Work.changeset(work, attrs))
    |> Ecto.Multi.run(:media, fn %{work: %Work{id: work_id}} ->
      media =
        attrs
        |> Map.get("media", [])
        |> Enum.map(fn %Plug.Upload{} = upload ->
          file = create_file!(upload)
          create_media!(file.filename, work_id, file.id)
        end)

      {:ok, media}
    end)
    |> Repo.transaction()
  end

  def delete_work(%Work{} = work) do
    Repo.delete(work)
  end

  def change_work(%Work{} = work) do
    Work.changeset(work, %{})
  end

  def create_media!(filename, work_id, file_id) do
    filename
    |> Media.changeset(work_id, file_id)
    |> Repo.insert!()
  end

  def list_media(work_id) do
    Repo.all(
      from media in Media,
        join: file in Art.File,
        on: file.id == media.file_id,
        where: [work_id: ^work_id],
        select: merge(media, %{filename: file.filename})
    )
  end

  def get_media_file(filename) when is_binary(filename) do
    Repo.one(
      from file in Art.File,
        join: media in Media,
        on: media.file_id == file.id,
        where: file.filename == ^filename
    )
  end

  def create_file!(%Plug.Upload{} = upload) do
    upload
    |> Art.File.changeset()
    |> Repo.insert!()
  end
end
