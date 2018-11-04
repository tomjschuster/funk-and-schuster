defmodule FunkAndSchusterWeb.Plugs.VerifyThesis do
  import Plug.Conn

  def init(opts), do: opts
  def call(conn, _opts), do: conn |> assign(:thesis_editable, conn.assigns.admin?)
end
