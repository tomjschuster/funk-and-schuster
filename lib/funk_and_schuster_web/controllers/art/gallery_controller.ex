defmodule FunkAndSchusterWeb.Art.GalleryController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.Art
  alias FunkAndSchuster.Art.Gallery

  def index(conn, _params) do
    galleries = Art.list_galleries()
    render(conn, "index.html", galleries: galleries)
  end

  def new(conn, _params) do
    render(conn, "new.html",
      media: Art.list_media(),
      changeset: Art.change_gallery(%Gallery{})
    )
  end

  def create(conn, %{"gallery" => gallery_params} = params) do
    case Art.create_gallery(gallery_params) do
      {:ok, gallery} ->
        conn
        |> put_flash(:info, "Gallery created successfully.")
        |> redirect(to: gallery_path(conn, :show, gallery))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, media: Art.list_media())
    end
  end

  def show(conn, %{"id" => id}) do
    gallery = Art.get_gallery!(id)
    render(conn, "show.html", gallery: gallery)
  end

  def edit(conn, %{"id" => id}) do
    gallery = Art.get_gallery!(id)

    render(conn, "edit.html",
      gallery: gallery,
      changeset: Art.change_gallery(gallery),
      media: Art.list_media()
    )
  end

  def update(conn, %{"id" => id, "gallery" => gallery_params} = params) do
    gallery = Art.get_gallery!(id)

    case Art.update_gallery(gallery, gallery_params) do
      {:ok, gallery} ->
        conn
        |> put_flash(:info, "Gallery updated successfully.")
        |> redirect(to: gallery_path(conn, :show, gallery))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", gallery: gallery, changeset: changeset, media: Art.list_media())
    end
  end

  def delete(conn, %{"id" => id}) do
    gallery = Art.get_gallery!(id)
    {:ok, _gallery} = Art.delete_gallery(gallery)

    conn
    |> put_flash(:info, "Gallery deleted successfully.")
    |> redirect(to: gallery_path(conn, :index))
  end
end
