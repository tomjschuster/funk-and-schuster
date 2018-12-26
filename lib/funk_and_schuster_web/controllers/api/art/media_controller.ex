defmodule FunkAndSchusterWeb.Api.Art.MediaController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.FileService
  alias FunkAndSchuster.ArtApi
  alias FunkAndSchuster.Art.Media

  action_fallback FunkAndSchusterWeb.FallbackController

  def index(conn, _params) do
    media = ArtApi.list_media()
    render(conn, "index.json", media: media)
  end

  def create(conn, %{"media" => media_params}) do
    file_info = %FileService.FileInfo{}

    with {:ok, %Media{} = media} <- ArtApi.create_media(file_info, media_params) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", Routes.api_art_media_path(conn, :show, media))
      |> render("show.json", media: media)
    end
  end

  def show(conn, %{"id" => id}) do
    media = ArtApi.get_media!(id)
    render(conn, "show.json", media: media)
  end

  def update(conn, %{"id" => id, "media" => media_params}) do
    media = ArtApi.get_media!(id)

    with {:ok, %Media{} = media} <- ArtApi.update_media(media, media_params) do
      render(conn, "show.json", media: media)
    end
  end

  def delete(conn, %{"id" => _id}) do
    # media = ArtApi.get_media!(id)

    # with {:ok, %Media{}} <- ArtApi.delete_media(media) do
    send_resp(conn, :no_content, "")
    # end
  end
end
