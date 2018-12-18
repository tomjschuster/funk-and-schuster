defmodule FunkAndSchuster.Tasks.StaticSite do
  def generate do
    opts = Application.fetch_env!(:funk_and_schuster, :static_site)

    firebase_opts =
      Application.fetch_env!(:funk_and_schuster, :firebase)
      |> Keyword.take([:project, :token])

    merged_opts = Keyword.merge(opts, firebase_opts)
    generate(merged_opts)
  end

  def generate(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> generate()

  def generate(opts) do
    cwd = File.cwd!()

    try do
      :ok = time("Building assets", "Assets built", fn -> build_static_assets() end)
      :ok = time("Generating site", "Site generated", fn -> generate_site(opts) end)
      :ok = time("Deploying site", "Site deployed", fn -> deploy(opts) end)
    rescue
      error ->
        IO.inspect(error)
        IO.puts("Something went wrong. See above output for more details.")
    end

    :ok = cleanup!(cwd, opts)
  end

  defp build_static_assets do
    File.cd!("assets")
    System.cmd("npm", ["deploy", "--production"])
    File.cd!("..")
    :ok
  end

  defp generate_site(%{
         hostname: hostname,
         static_path: static_path,
         static_dirs: static_dirs,
         slugs: slugs,
         output: output
       }) do
    File.mkdir_p!(output)
    File.mkdir_p!(output <> "site")
    copy_static!(static_path, static_dirs, output)
    generate_html!(hostname, slugs, output)
  end

  defp copy_static!(static_path, static_dirs, output) do
    static_dirs
    |> Enum.map(&Task.async(fn -> copy_static_dir!(&1, static_path, output) end))
    |> Enum.each(&Task.await/1)
  end

  defp copy_static_dir!(dir, static_path, output) do
    File.mkdir_p!(output <> "site/" <> dir)
    File.cp_r!(static_path <> dir, output <> "site/" <> dir)
    :ok
  end

  defp generate_html!(hostname, slugs, output) do
    slugs
    |> Enum.map(&Task.async(fn -> fetch_and_write_html!(&1, hostname, output) end))
    |> Enum.each(fn task -> :ok = Task.await(task) end)
  end

  defp fetch_and_write_html!(slug, hostname, output) do
    %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(hostname <> endpoint(slug))
    File.write!(output <> "site/" <> filename(slug), body)
  end

  defp endpoint("index"), do: endpoint("")
  defp endpoint(slug), do: "/" <> slug
  defp filename(slug), do: slug <> ".html"

  @firebase_json """
    {
      "hosting": {
        "public": "site",
        "ignore": [
          "firebase.json",
          "**/.*"
        ],
        "trailingSlash": false,
        "cleanUrls": true,
        "headers": [
          {
            "source": "**/*.@(jpg|jpeg|gif|png)",
            "headers": [ 
              {
                "key": "Cache-Control",
                "value": "max-age=604800"
              }
            ]
          }
        ]
      }
    }
  """

  defp deploy(%{output: output, project: project, token: token}) do
    cwd = File.cwd!()
    File.write!(output <> "firebase.json", @firebase_json)
    File.cd!(output)
    {_, 0} = System.cmd("firebase", ["deploy", "-P", project], env: [{"FIREBASE_TOKEN", token}])
    File.cd!(cwd)
  end

  defp cleanup!(cwd, %{output: output}) do
    File.cd!(cwd)
    File.rm_rf!(output)
    :ok
  end

  defp time(start_msg, end_msg, f) do
    then = now()
    IO.puts(start_msg <> "...")
    :ok = result = f.()
    IO.puts(end_msg <> " in #{(now() - then) / 1000}ms")
    result
  end

  defp now, do: DateTime.utc_now() |> DateTime.to_unix(:milliseconds)
end
