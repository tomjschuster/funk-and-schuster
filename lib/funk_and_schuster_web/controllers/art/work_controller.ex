defmodule FunkAndSchusterWeb.Art.WorkController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.{Art, FileService}
  alias FunkAndSchuster.Art.Work

  def action(conn, _) do
    artist = Art.get_artist!(conn.params["artist_id"])
    args = [conn, conn.params, artist]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, _params, artist) do
    works = Art.list_works(artist)
    render(conn, "index.html", artist: artist, works: works)
  end

  def new(conn, _params, artist) do
    changeset = Art.change_work(%Work{})
    render(conn, "new.html", artist: artist, changeset: changeset)
  end

  def create(conn, %{"work" => work_params}, artist) do
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

  def show(conn, %{"id" => id}, artist) do
    work = Art.get_work!(id)
    media = Art.list_work_media(id)
    render(conn, "show.html", artist: artist, work: work, media: media)
  end

  def edit(conn, %{"id" => id}, artist) do
    work = Art.get_work!(id)
    changeset = Art.change_work(work)
    render(conn, "edit.html", artist: artist, work: work, changeset: changeset)
  end

  def update(conn, %{"id" => id, "work" => work_params}, artist) do
    work = Art.get_work!(id)

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
        |> redirect(to: artist_work_path(conn, :show, artist, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)
        render(conn, "edit.html", artist: artist, work: work, changeset: changeset)
    end
  end

  defp get_deleted_filenames(params) do
    params
    |> Map.get("media", [])
    |> Stream.filter(fn {_k, v} -> v["deleted?"] == "true" end)
    |> Enum.map(fn {_k, v} -> v["filename"] end)
  end
end
