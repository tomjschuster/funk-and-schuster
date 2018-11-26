defmodule FunkAndSchusterWeb.Art.ArtController do
  use FunkAndSchusterWeb, :controller

  def index(conn, _params), do: render(conn, :index)
end
