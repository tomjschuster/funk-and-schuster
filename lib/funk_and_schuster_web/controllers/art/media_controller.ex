defmodule FunkAndSchusterWeb.Art.MediaController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.{Art, FileService}
  alias FunkAndSchuster.Art.Media

  def index(conn, %{"artist_id" => _artist_id, "work_id" => work_id}) do
    render(conn, "index-for-artist-work.html",
      work: Art.get_work_with_artist!(work_id),
      media: Art.list_media_for_work(work_id)
    )
  end

  def index(conn, %{"artist_id" => artist_id}) do
    render(conn, "index-for-artist.html",
      artist: Art.get_artist!(artist_id),
      media: Art.list_media_for_artist(artist_id)
    )
  end

  def index(conn, %{"work_id" => work_id}) do
    render(conn, "index-for-work.html",
      work: Art.get_work!(work_id),
      media: Art.list_media_for_work(work_id)
    )
  end

  def index(conn, _params),
    do: render(conn, "index.html", media: Art.list_media())

  def new(conn, %{"artist_id" => _artist_id, "work_id" => work_id}) do
    render(conn, "new-for-artist-work.html",
      work: Art.get_work_with_artist!(work_id),
      changeset: Art.change_media(%Media{work_id: work_id}),
      allow_upload?: true
    )
  end

  def new(conn, %{"artist_id" => artist_id}) do
    render(conn, "new-for-artist.html",
      artist: Art.get_artist!(artist_id),
      changeset: Art.change_media(%Media{artist_id: artist_id}),
      allow_upload?: true
    )
  end

  def new(conn, %{"work_id" => work_id}) do
    render(conn, "new-for-work.html",
      work: Art.get_work!(work_id),
      changeset: Art.change_media(%Media{work_id: work_id}),
      allow_upload?: true
    )
  end

  def new(conn, _params) do
    render(conn, "new.html",
      works: Art.list_works_with_artist(),
      artists: Art.list_artists(),
      changeset: Art.change_media(%Media{}),
      allow_upload?: true
    )
  end

  def create(conn, %{"artist_id" => _artist_id, "work_id" => work_id, "media" => media_params}) do
    work = Art.get_work_with_artist!(work_id)

    case FileService.upload_file(media_params["file"]) do
      {:ok, file_info} ->
        case Art.create_work_media(file_info, work, media_params) do
          {:ok, media} ->
            conn
            |> put_flash(:info, "Media created successfully.")
            |> redirect(to: artist_work_media_path(conn, :show, work.artist, work, media))

          {:error, %Ecto.Changeset{} = changeset} ->
            FileService.delete_file!(file_info)

            render(conn, "new-for-artist-work.html",
              work: work,
              changeset: changeset,
              allow_upload?: true
            )
        end

      {:error, :no_file} ->
        IO.inspect("no file")

        render(conn, "new-for-artist-work.html",
          work: work,
          changeset: Media.no_file_changeset(media_params),
          allow_upload?: true
        )
    end
  end

  def create(conn, %{"artist_id" => artist_id, "media" => media_params}) do
    artist = Art.get_artist!(artist_id)

    case FileService.upload_file(media_params["file"]) do
      {:ok, file_info} ->
        case Art.create_artist_media(file_info, artist, media_params) do
          {:ok, media} ->
            conn
            |> put_flash(:info, "Media created successfully.")
            |> redirect(to: artist_media_path(conn, :show, artist, media))

          {:error, %Ecto.Changeset{} = changeset} ->
            FileService.delete_file!(file_info)

            render(conn, "new-for-artist.html",
              artist: artist,
              changeset: changeset,
              allow_upload?: true
            )
        end

      {:error, :no_file} ->
        IO.inspect("no file")

        render(conn, "new-for-artist.html",
          artist: artist,
          changeset: Media.no_file_changeset(media_params),
          allow_upload?: true
        )
    end
  end

  def create(conn, %{"work_id" => work_id, "media" => media_params}) do
    work = Art.get_work!(work_id)

    case FileService.upload_file(media_params["file"]) do
      {:ok, file_info} ->
        case Art.create_work_media(file_info, work, media_params) do
          {:ok, media} ->
            conn
            |> put_flash(:info, "Media created successfully.")
            |> redirect(to: work_media_path(conn, :show, work, media))

          {:error, %Ecto.Changeset{} = changeset} ->
            FileService.delete_file!(file_info)

            render(conn, "new-for-work.html",
              work: work,
              changeset: changeset,
              allow_upload?: true
            )
        end

      {:error, :no_file} ->
        IO.inspect("no file")

        render(conn, "new-for-work.html",
          work: work,
          changeset: Media.no_file_changeset(media_params),
          allow_upload?: true
        )
    end
  end

  def create(conn, %{"media" => media_params} = params) do
    IO.inspect(params)

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

  def show(conn, %{"artist_id" => _artist_id, "work_id" => _work_id, "id" => id}),
    do: render(conn, "show-for-artist-work.html", media: Art.get_media!(id))

  def show(conn, %{"artist_id" => _artist_id, "id" => id}),
    do: render(conn, "show-for-artist.html", media: Art.get_media!(id))

  def show(conn, %{"work_id" => _work_id, "id" => id}),
    do: render(conn, "show-for-work.html", media: Art.get_media!(id))

  def show(conn, %{"id" => id}),
    do: render(conn, "show.html", media: Art.get_media!(id))

  def edit(conn, %{"artist_id" => _artist_id, "work_id" => _work_id, "id" => id}) do
    media = Art.get_media!(id)

    render(conn, "edit-for-artist-work.html",
      media: media,
      changeset: Art.change_media(media),
      allow_upload?: false
    )
  end

  def edit(conn, %{"artist_id" => _artist_id, "id" => id}) do
    media = Art.get_media!(id)

    render(conn, "edit-for-artist.html",
      media: media,
      changeset: Art.change_media(media),
      allow_upload?: false
    )
  end

  def edit(conn, %{"work_id" => _work_id, "id" => id}) do
    media = Art.get_media!(id)

    render(conn, "edit-for-work.html",
      media: media,
      changeset: Art.change_media(media),
      allow_upload?: false
    )
  end

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

  def update(conn, %{
        "artist_id" => _artist_id,
        "work_id" => _work_id,
        "id" => id,
        "media" => media_params
      }) do
    media = Art.get_media!(id)

    case Art.update_media(media, media_params) do
      {:ok, media} ->
        conn
        |> put_flash(:info, "Media updated successfully.")
        |> redirect(to: artist_work_media_path(conn, :show, media.work.artist, media.work, media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit-for-artist-work.html",
          media: media,
          changeset: changeset,
          allow_upload?: false
        )
    end
  end

  def update(conn, %{"artist_id" => _artist_id, "id" => id, "media" => media_params}) do
    media = Art.get_media!(id)

    case Art.update_media(media, media_params) do
      {:ok, media} ->
        conn
        |> put_flash(:info, "Media updated successfully.")
        |> redirect(to: artist_media_path(conn, :show, media.artist, media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit-for-artist.html",
          media: media,
          changeset: changeset,
          allow_upload?: false
        )
    end
  end

  def update(conn, %{"work_id" => _work_id, "id" => id, "media" => media_params}) do
    media = Art.get_media!(id)

    case Art.update_media(media, media_params) do
      {:ok, media} ->
        conn
        |> put_flash(:info, "Media updated successfully.")
        |> redirect(to: work_media_path(conn, :show, media.work, media))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit-for-work.html",
          media: media,
          changeset: changeset,
          allow_upload?: false
        )
    end
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
