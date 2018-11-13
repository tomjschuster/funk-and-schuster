defmodule FunkAndSchusterWeb.Art.ArtistController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.{Art, FileService}
  alias FunkAndSchuster.Art.Artist

  def index(conn, _params) do
    artists = Art.list_artists()
    render(conn, "index.html", artists: artists)
  end

  def new(conn, _params) do
    changeset = Art.change_artist(%Artist{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"artist" => artist_params}) do
    files =
      artist_params
      |> Map.get("new_media", [])
      |> FileService.batch_upload_files!()

    case Art.create_artist(artist_params, files) do
      {:ok, %{artist: artist}} ->
        conn
        |> put_flash(:info, "Artist created successfully.")
        |> redirect(to: artist_path(conn, :show, artist))

      {:error, :artist, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    artist = Art.get_artist_with_assocs!(id)
    render(conn, "show.html", artist: artist)
  end

  def edit(conn, %{"id" => id}) do
    artist = Art.get_artist_with_assocs!(id)
    changeset = Art.change_artist(artist)
    render(conn, "edit.html", artist: artist, changeset: changeset)
  end

  def update(conn, %{"id" => id, "artist" => artist_params}) do
    artist = Art.get_artist_with_assocs!(id)

    files =
      artist_params
      |> Map.get("new_media", [])
      |> FileService.batch_upload_files!()

    case Art.update_artist(artist, artist_params, files) do
      {:ok, %{artist: artist}} ->
        conn
        |> put_flash(:info, "Artist updated successfully.")
        |> redirect(to: artist_path(conn, :show, artist))

      {:error, :artist, %Ecto.Changeset{} = changeset, _errors} ->
        FileService.batch_delete_files!(files)
        render(conn, "edit.html", artist: artist, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    artist = Art.get_artist!(id)
    {:ok, _artist} = Art.delete_artist(artist)

    conn
    |> put_flash(:info, "Artist deleted successfully.")
    |> redirect(to: artist_path(conn, :index))
  end
end
