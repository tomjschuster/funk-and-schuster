defmodule FunkAndSchusterWeb.PageController do
  use FunkAndSchusterWeb, :controller

  def index(conn, _params), do: render(conn, :index)
  def about(conn, _params), do: render(conn, :about)
  def gallery(conn, _params), do: render(conn, :gallery)
  def artists(conn, _params), do: render(conn, :artists)
  def contact(conn, _params), do: render(conn, :contact)
end
