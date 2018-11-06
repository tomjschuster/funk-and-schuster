defmodule FunkAndSchusterWeb.Art.MediaController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.Art
  alias FunkAndSchuster.Art.Media

  def index(conn, _params) do
    media = Art.list_media()
    render(conn, "index.html", media: media)
  end

  def new(conn, _params) do
    changeset = Art.change_media(%Media{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"media" => media_params}) do
    case Art.create_media(media_params) do
      {:ok, media} ->
        conn
        |> put_flash(:info, "Media created successfully.")
        |> redirect(to: media_path(conn, :show, media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    media = Art.get_media!(id)
    render(conn, "show.html", media: media)
  end

  def edit(conn, %{"id" => id}) do
    media = Art.get_media!(id)
    changeset = Art.change_media(media)
    render(conn, "edit.html", media: media, changeset: changeset)
  end

  def update(conn, %{"id" => id, "media" => media_params}) do
    media = Art.get_media!(id)

    case Art.update_media(media, media_params) do
      {:ok, media} ->
        conn
        |> put_flash(:info, "Media updated successfully.")
        |> redirect(to: media_path(conn, :show, media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", media: media, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    media = Art.get_media!(id)
    {:ok, _media} = Art.delete_media(media)

    conn
    |> put_flash(:info, "Media deleted successfully.")
    |> redirect(to: media_path(conn, :index))
  end
end
