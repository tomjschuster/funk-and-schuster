defmodule FunkAndSchusterWeb.Plugs.RequireAdmin do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts), do: conn |> require_admin()

  defp require_admin(%Plug.Conn{assigns: %{admin?: true}} = conn),
    do: conn

  defp require_admin(conn),
    do: conn |> Phoenix.Controller.redirect(to: "/not-found") |> halt()
end
