defmodule FunkAndSchusterWeb.Api.Art.ArtistView do
  use FunkAndSchusterWeb, :view
  alias FunkAndSchusterWeb.Api.Art.ArtistView

  def render("index.json", %{artists: artists}) do
    %{data: render_many(artists, ArtistView, "artist.json")}
  end

  def render("show.json", %{artist: artist}) do
    %{data: render_one(artist, ArtistView, "artist.json")}
  end

  def render("artist.json", %{artist: artist}) do
    %{
      id: artist.id,
      first_name: artist.first_name,
      last_name: artist.last_name,
      dob: artist.dob |> Timex.to_datetime() |> Timex.to_unix()
    }
  end
end
