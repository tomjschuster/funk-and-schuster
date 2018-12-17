defmodule FunkAndSchuster.Tasks.StaticSite do
  @default_opts [
    hostname: "http://localhost:4000",
    static_path: "./priv/static/",
    static_dirs: ~w(images icons),
    slugs: ~w(index about gallery contacts process),
    output: "/home/tom/site/"
  ]

  def generate do
    opts = Application.get_env(:funk_and_schuster, :static_site, @default_opts)

    generate(opts)
  end

  def generate(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> generate()

  def generate(%{
        hostname: hostname,
        static_path: static_path,
        static_dirs: static_dirs,
        slugs: slugs,
        output: output
      }) do
    then = now()

    File.mkdir_p!(output)

    static_count = copy_static!(static_path, static_dirs, output)
    html_count = copy_html!(hostname, slugs, output)

    IO.puts("#{static_count + html_count} files copied in #{(now() - then) / 1000}ms")
  end

  defp copy_static!(static_path, static_dirs, output) do
    static_dirs
    |> Enum.map(&Task.async(fn -> copy_static_dir!(&1, static_path, output) end))
    |> Enum.map(&Task.await/1)
    |> Enum.sum()
  end

  defp copy_static_dir!(dir, static_path, output) do
    File.mkdir_p!(output <> dir)
    files = File.cp_r!(static_path <> dir, output <> dir)
    length(files)
  end

  defp copy_html!(hostname, slugs, output) do
    slugs
    |> Enum.map(&Task.async(fn -> fetch_and_write_html!(&1, hostname, output) end))
    |> Enum.each(&Task.await/1)

    length(slugs)
  end

  defp fetch_and_write_html!(slug, hostname, output) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(hostname <> endpoint(slug))
    :ok = File.write!(output <> filename(slug), body)
  end

  defp endpoint("index"), do: endpoint("")
  defp endpoint(slug), do: "/" <> slug
  defp filename(slug), do: slug <> ".html"

  defp now, do: DateTime.utc_now() |> DateTime.to_unix(:milliseconds)
end
