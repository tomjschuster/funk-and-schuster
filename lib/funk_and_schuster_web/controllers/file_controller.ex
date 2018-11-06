defmodule FunkAndSchusterWeb.FileController do
  use FunkAndSchusterWeb, :controller
  alias FunkAndSchuster.{Repo, Art}

  def show(conn, %{"filename" => filename}) do
    case Repo.get_by(Art.File, filename: filename) do
      %Art.File{content_type: content_type, data: data} ->
        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, data)

      nil ->
        send_resp(conn, :not_found, "")
    end
  end
end
