defmodule FunkAndSchusterWeb.LayoutView do
  use FunkAndSchusterWeb, :view

  def page_class(conn) do
    case conn.path_info do
      [] -> "home"
      ["about" | _rest] -> "about"
      ["gallery" | _rest] -> "gallery"
      ["artists" | _rest] -> "artists"
      ["contact" | _rest] -> "contact"
      _ -> ""
    end
  end
end
