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
      changeset: Art.change_gallery(%Gallery{gallery_media: []})
    )
  end

  def create(conn, %{"gallery" => gallery_params} = params) do
    IO.inspect(params)

    gallery_media =
      params
      |> Map.get("gallery_media", [])
      |> Enum.map(&Poison.decode!/1)

    IO.inspect(params)

    case Art.create_gallery(Map.put(gallery_params, "gallery_media", gallery_media)) do
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
    IO.inspect(gallery)
    IO.inspect(Art.change_gallery(gallery))

    render(conn, "edit.html",
      gallery: gallery,
      changeset: Art.change_gallery(gallery),
      media: Art.list_media()
    )
  end

  def update(conn, %{"id" => id, "gallery" => gallery_params} = params) do
    IO.inspect(params)
    gallery = Art.get_gallery!(id)

    gallery_media =
      params
      |> Map.get("gallery_media", [])
      |> Enum.map(&Poison.decode!/1)

    IO.inspect(params)

    case Art.update_gallery(gallery, Map.put(gallery_params, "gallery_media", gallery_media)) do
      {:ok, gallery} ->
        conn
        |> put_flash(:info, "Gallery updated successfully.")
        |> redirect(to: gallery_path(conn, :show, gallery))

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
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
