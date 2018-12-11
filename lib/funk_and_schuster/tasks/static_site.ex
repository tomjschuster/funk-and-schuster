defmodule FunkAndSchuster.Tasks.StaticSite do
  @base_path Application.fetch_env!(:funk_and_schuster, :base_path)
  @paths %{
    "/" => "/index.html",
    "/about" => "/about.html",
    "/gallery" => "/gallery.html",
    "/contact" => "/contact.html",
    "/process" => "/process.html"
  }

  @output "priv/static/test"

  def generate do
    File.mkdir_p!(@output)

    @paths
    |> Enum.map(&Task.async(fn -> fetch_and_write!(&1) end))
    |> Enum.map(&Task.await/1)
    |> Enum.all?(&(IO.inspect(&1) == :ok))
    |> case do
      true -> :ok
      false -> :error
    end
  end

  defp fetch_and_write!({path, filename}) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(@base_path <> path)
    File.write(@output <> filename, body)
  end
end
