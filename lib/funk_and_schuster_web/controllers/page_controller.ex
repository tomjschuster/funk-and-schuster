defmodule FunkAndSchusterWeb.PageController do
  use FunkAndSchusterWeb, :controller

  plug FunkAndSchusterWeb.Plugs.VerifyThesis

  def index(conn, _params), do: render(conn, :index)
  def about(conn, _params), do: render(conn, :about)
  def gallery(conn, _params), do: render(conn, :gallery)
  def process(conn, _params), do: render(conn, :process)
  def contact(conn, _params), do: render(conn, :contact)
end
