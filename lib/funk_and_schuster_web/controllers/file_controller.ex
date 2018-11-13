defmodule FunkAndSchusterWeb.FileController do
  use FunkAndSchusterWeb, :controller
  alias FunkAndSchuster.FileService

  def show(conn, %{"filename" => filename}) do
    case FileService.get_file_by_filename(filename) do
      %FileService.FileInfo{content_type: content_type, data: data} ->
        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, data)

      nil ->
        send_resp(conn, :not_found, "")
    end
  end
end
