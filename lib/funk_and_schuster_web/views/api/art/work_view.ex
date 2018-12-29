defmodule FunkAndSchusterWeb.Api.Art.WorkView do
  use FunkAndSchusterWeb, :view
  alias FunkAndSchusterWeb.Api.Art.WorkView

  def render("index.json", %{works: works}) do
    %{data: render_many(works, WorkView, "work.json")}
  end

  def render("show.json", %{work: work}) do
    %{data: render_one(work, WorkView, "work.json")}
  end

  def render("work.json", %{work: work}) do
    %{
      id: work.id,
      artist_id: work.artist_id,
      title: work.title,
      date: work.date |> Timex.to_datetime() |> Timex.to_unix(),
      medium: work.medium,
      dimensions: work.dimensions
    }
  end
end
