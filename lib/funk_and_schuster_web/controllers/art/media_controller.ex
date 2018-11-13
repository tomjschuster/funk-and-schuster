defmodule FunkAndSchusterWeb.Art.MediaController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.{Art, FileService}
  alias FunkAndSchuster.Art.Media

  def index(conn, _params),
    do: render(conn, "index.html", media: Art.list_media())

  def new(conn, _params) do
    render(conn, "new.html",
      works: Art.list_works_with_artist(),
      artists: Art.list_artists(),
      changeset: Art.change_media(%Media{}),
      allow_upload?: true
    )
  end

  def create(conn, %{"media" => media_params}) do
    case FileService.upload_file(media_params["file"]) do
      {:ok, file_info} ->
        case Art.create_media(file_info, media_params) do
          {:ok, media} ->
            conn
            |> put_flash(:info, "Media created successfully.")
            |> redirect(to: media_path(conn, :show, media))

          {:error, %Ecto.Changeset{} = changeset} ->
            FileService.delete_file!(file_info)

            render(conn, "new.html",
              works: Art.list_works_with_artist(),
              artists: Art.list_artists(),
              changeset: changeset,
              allow_upload?: true
            )
        end

      {:error, :no_file} ->
        IO.inspect("no file")

        render(conn, "new.html",
          works: Art.list_works_with_artist(),
          artists: Art.list_artists(),
          changeset: Media.no_file_changeset(media_params),
          allow_upload?: true
        )
    end
  end

  def show(conn, %{"id" => id}),
    do: render(conn, "show.html", media: Art.get_media!(id))

  def edit(conn, %{"id" => id}) do
    media = Art.get_media!(id)

    render(conn, "edit.html",
      media: media,
      works: Art.list_works_with_artist(),
      artists: Art.list_artists(),
      changeset: Art.change_media(media),
      allow_upload?: false
    )
  end

  def update(conn, %{"id" => id, "media" => media_params}) do
    media = Art.get_media!(id)

    case Art.update_media(media, media_params) do
      {:ok, media} ->
        conn
        |> put_flash(:info, "Media updated successfully.")
        |> redirect(to: media_path(conn, :show, media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html",
          works: Art.list_works_with_artist(),
          artists: Art.list_artists(),
          media: media,
          changeset: changeset,
          allow_upload?: false
        )
    end
  end
end
