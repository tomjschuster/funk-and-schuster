defmodule FunkAndSchusterWeb.LayoutView do
  use FunkAndSchusterWeb, :view

  def nav_link(conn, page, label, opts \\ []) do
    all_opts =
      [to: Routes.page_path(conn, page), role: "menuitem", class: active_class(conn, page)] ++
        opts

    link(label, all_opts)
  end

  def active_class(conn, page),
    do: if(Routes.page_path(conn, page) == conn.request_path, do: "active", else: "")
end
