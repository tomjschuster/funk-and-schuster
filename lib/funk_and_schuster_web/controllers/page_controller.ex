defmodule FunkAndSchusterWeb.PageController do
  use FunkAndSchusterWeb, :controller

  def admin_host?(conn) do
    case conn.host do
      "admin.funkandschuster.art" -> true
      "admin.localhost" -> true
      _ -> false
    end
  end


  def index(conn, _params), do: render(conn, :index, thesis_editable: admin_host?(conn))
  def about(conn, _params), do: render(conn, :about, thesis_editable: admin_host?(conn))
  def gallery(conn, _params), do: render(conn, :gallery, thesis_editable: admin_host?(conn))
  def artists(conn, _params), do: render(conn, :artists, thesis_editable: admin_host?(conn))
  def contact(conn, _params), do: render(conn, :contact, thesis_editable: admin_host?(conn))
end
