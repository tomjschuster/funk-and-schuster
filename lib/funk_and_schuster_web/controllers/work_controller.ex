defmodule FunkAndSchusterWeb.WorkController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.Art
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
    case Art.create_work(artist, work_params, work_params["media"] || []) do
      {:ok, %{work: work}} ->
        IO.inspect(work)

        conn
        |> put_flash(:info, "Work created successfully.")
        |> redirect(to: artist_work_path(conn, :show, artist, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        render(conn, "new.html", artist: artist, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, artist) do
    work = Art.get_work!(id)
    media = Art.list_media(id)
    render(conn, "show.html", artist: artist, work: work, media: media)
  end

  def edit(conn, %{"id" => id}, artist) do
    work = Art.get_work!(id)
    changeset = Art.change_work(work)
    render(conn, "edit.html", artist: artist, work: work, changeset: changeset)
  end

  def update(conn, %{"id" => id, "work" => work_params}, artist) do
    work = Art.get_work!(id)

    case Art.update_work(work, work_params, work_params["media"] || []) do
      {:ok, %{work: work}} ->
        IO.inspect(work)

        conn
        |> put_flash(:info, "Work updated successfully.")
        |> redirect(to: artist_work_path(conn, :show, artist, work))

      {:error, :work, %Ecto.Changeset{} = changeset, _errors} ->
        render(conn, "edit.html", artist: artist, work: work, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, artist) do
    work = Art.get_work!(id)
    {:ok, _work} = Art.delete_work(work)

    conn
    |> put_flash(:info, "Work deleted successfully.")
    |> redirect(to: artist_work_path(conn, :index, artist))
  end
end
