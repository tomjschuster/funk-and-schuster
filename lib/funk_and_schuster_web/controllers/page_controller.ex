defmodule FunkAndSchusterWeb.PageController do
  use FunkAndSchusterWeb, :controller

  def index(conn, _params), do: render(conn, :index)
  def about(conn, _params), do: render(conn, :about)
  def artwork(conn, _params), do: render(conn, :artwork)
  def print_with_us(conn, _params), do: render(conn, :print_with_us)
  def contact(conn, _params), do: render(conn, :contact)
end
