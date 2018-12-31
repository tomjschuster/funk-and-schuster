defmodule FunkAndSchusterWeb.Api.Art.ArtistController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.ArtApi
  alias FunkAndSchuster.Art.Artist

  action_fallback FunkAndSchusterWeb.FallbackController

  def index(conn, _params) do
    artists = ArtApi.list_artists()
    render(conn, "index.json", artists: artists)
  end

  def create(conn, %{"artist" => artist_params}) do
    files = []

    with {:ok, %{artist: %Artist{} = artist}} <- ArtApi.create_artist(artist_params, files) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", Routes.api_art_artist_path(conn, :show, artist))
      |> render("id.json", artist: artist)
    end
  end

  def show(conn, %{"id" => id}) do
    artist = ArtApi.get_artist!(id)
    render(conn, "show.json", artist: artist)
  end

  def update(conn, %{"id" => id, "artist" => artist_params}) do
    files = []
    artist = ArtApi.get_artist!(id)

    with {:ok, %Artist{} = artist} <- ArtApi.update_artist(artist, artist_params, files) do
      render(conn, "show.json", artist: artist)
    end
  end

  def delete(conn, %{"id" => _id}) do
    # artist = ArtApi.get_artist!(id)

    # with {:ok, %Artist{}} <- ArtApi.delete_artist(artist) do
    send_resp(conn, :no_content, "")
    # end
  end
end
