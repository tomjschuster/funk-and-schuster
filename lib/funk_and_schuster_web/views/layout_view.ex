defmodule FunkAndSchusterWeb.LayoutView do
  use FunkAndSchusterWeb, :view

  def nav_link(conn, page, label),
    do: link(label, to: page_path(conn, page), class: active_class(conn, page))

  def active_class(conn, page),
    do: if(page_path(conn, page) == conn.request_path, do: "active", else: "")
end
