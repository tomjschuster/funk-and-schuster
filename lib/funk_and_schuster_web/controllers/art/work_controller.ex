defmodule FunkAndSchusterWeb.Art.WorkController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.{Art, FileService}
  alias FunkAndSchuster.Art.Work

  def index(conn, %{"artist_id" => artist_id}) do
    artist = Art.get_artist!(artist_id)
    works = Art.list_artist_works_with_media(artist_id)
    render(conn, "index-for-artist.html", artist: artist, works: works)
  end

  def index(conn, _params) do
    works = Art.list_works_with_artist_and_media()
    render(conn, "index.html", works: works)
  end

  def new(conn, %{"artist_id" => artist_id}) do
    render(conn, "new-for-artist.html",
      artist: Art.get_artist!(artist_id),
      changeset: Art.change_work(%Work{artist_id: artist_id}),
      artists: Art.list_artists()
    )
  end

  def new(conn, _params) do
    render(conn, "new.html",
      changeset: Art.change_work(%Work{}),
      artists: Art.list_artists()
    )
  end

  def create(conn, %{"artist_id" => artist_id, "work" => work_params}) do
    artist = Art.get_artist!(artist_id)

    files =
      work_params
      |> Map.get("new_media", [])
      |> FileService.batch_upload_files!()

    case Art.create_work_for_artist(artist, work_params, files) do
      {:ok, %{work: work}} ->
        conn
        |> put_flash(:info, "Work created successfully.")
        |> redirect(to: artist_work_path(conn, :show, artist, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)
        render(conn, "new-for-artist.html", artist: artist, changeset: changeset)
    end
  end

  def create(conn, %{"work" => work_params}) do
    files =
      work_params
      |> Map.get("new_media", [])
      |> FileService.batch_upload_files!()

    case Art.create_work(work_params, files) do
      {:ok, %{work: work}} ->
        conn
        |> put_flash(:info, "Work created successfully.")
        |> redirect(to: work_path(conn, :show, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)
        render(conn, "new.html", changeset: IO.inspect(changeset), aritsts: Art.list_artists())
    end
  end

  def show(conn, %{"artist_id" => artist_id, "id" => id}) do
    render(conn, "show-for-artist.html", work: Art.get_work_with_media_and_artist!(id))
  end

  def show(conn, %{"id" => id}) do
    render(conn, "show.html", work: Art.get_work_with_media_and_artist!(id))
  end

  def edit(conn, %{"artist_id" => _artist_id, "id" => id}) do
    work = Art.get_work_with_media_and_artist!(id)

    render(conn, "edit-for-artist.html",
      work: work,
      changeset: Art.change_work(work),
      artists: Art.list_artists()
    )
  end

  def edit(conn, %{"id" => id}) do
    work = Art.get_work_with_media_and_artist!(id)

    render(conn, "edit.html",
      work: work,
      changeset: Art.change_work(work),
      artists: Art.list_artists()
    )
  end

  def update(conn, %{"artist_id" => _artist_id, "id" => id, "work" => work_params}) do
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
        render(conn, "edit-for-artist.html", work: work, changeset: changeset)
    end
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
        |> redirect(to: work_path(conn, :show, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)

        render(conn, "edit.html",
          work: work,
          changeset: IO.inspect(changeset),
          artists: Art.list_artists()
        )
    end
  end

  defp get_deleted_filenames(params) do
    params
    |> Map.get("media", [])
    |> Stream.filter(fn {_k, v} -> v["deleted?"] == "true" end)
    |> Enum.map(fn {_k, v} -> IO.inspect(v) && v["filename"] end)
  end
end
