defmodule FunkAndSchusterWeb.MediaController do
  use FunkAndSchusterWeb, :controller
  alias FunkAndSchuster.Art
  alias FunkAndSchuster.Art.File

  def show(conn, %{"filename" => filename}) do
    case Art.get_media(filename) do
      %File{content_type: content_type, data: data} ->
        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, data)

      nil ->
        send_resp(conn, :not_found, "")
    end
  end
end
