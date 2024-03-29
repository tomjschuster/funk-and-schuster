defmodule FunkAndSchusterWeb.PageView do
  use FunkAndSchusterWeb, :view
  alias FunkAndSchusterWeb.LayoutView

  def page_class(conn) do
    case conn.path_info do
      [] -> "home"
      ["about" | _rest] -> "about"
      ["gallery" | _rest] -> "gallery"
      ["process" | _rest] -> "process"
      ["contact" | _rest] -> "contact"
      _ -> ""
    end
  end
end
