defmodule FunkAndSchusterWeb.Art.WorkController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.{Art, FileService}
  alias FunkAndSchuster.Art.Work

  def index(conn, %{"artist_id" => artist_id}) do
    artist = Art.get_artist!(artist_id)
    works = Art.list_artist_works_with_media(artist_id)
    render(conn, "index.html", artist: artist, works: works)
  end

  def new(conn, %{"artist_id" => artist_id}) do
    artist = Art.get_artist!(artist_id)
    changeset = Art.change_work(%Work{})
    render(conn, "new.html", artist: artist, changeset: changeset)
  end

  def create(conn, %{"artist_id" => artist_id, "work" => work_params}) do
    artist = Art.get_artist!(artist_id)

    files =
      work_params
      |> Map.get("new_media", [])
      |> FileService.batch_upload_files!()

    case Art.create_work(artist, work_params, files) do
      {:ok, %{work: work}} ->
        conn
        |> put_flash(:info, "Work created successfully.")
        |> redirect(to: artist_work_path(conn, :show, artist, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)
        render(conn, "new.html", artist: artist, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    work = Art.get_work_with_media_and_artist!(id)
    render(conn, "show.html", work: work)
  end

  def edit(conn, %{"id" => id}) do
    work = Art.get_work_with_media_and_artist!(id)
    changeset = Art.change_work(work)
    render(conn, "edit.html", work: work, changeset: changeset)
  end

  def update(conn, %{"id" => id, "work" => work_params}) do
    work = Art.get_work_with_media_and_artist!(id)

    files =
      work_params
      |> Map.get("new_media", [])
      |> FileService.batch_upload_files!()

    case Art.update_work(work, work_params, files) do
      {:ok, %{work: work}} ->
        work_params
        |> get_deleted_filenames()
        |> FileService.batch_delete_files!()

        conn
        |> put_flash(:info, "Work updated successfully.")
        |> redirect(to: artist_work_path(conn, :show, work.artist, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)
        render(conn, "edit.html", work: work, changeset: changeset)
    end
  end

  defp get_deleted_filenames(params) do
    params
    |> Map.get("media", [])
    |> Stream.filter(fn {_k, v} -> v["deleted?"] == "true" end)
    |> Enum.map(fn {_k, v} -> IO.inspect(v) && v["filename"] end)
  end
end
