defmodule FunkAndSchusterWeb.Plugs.VerifyAdmin do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts), do: conn |> assign(:admin?, admin_subdomain?(conn))

  defp admin_subdomain?(%Plug.Conn{host: host}) do
    case parse_subdomain(host) do
      "admin" -> true
      _ -> false
    end
  end

  defp parse_subdomain(host) do
    case String.split(host, ".") do
      [subdomain, "localhost"] -> subdomain
      [subdomain, _domain, _top_level_domain | _] -> subdomain
      _ -> nil
    end
  end
end
