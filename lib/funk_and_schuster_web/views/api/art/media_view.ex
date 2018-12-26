defmodule FunkAndSchusterWeb.Api.Art.MediaView do
  use FunkAndSchusterWeb, :view
  alias FunkAndSchusterWeb.Api.Art.MediaView

  def render("index.json", %{media: media}) do
    %{data: render_many(media, MediaView, "media.json")}
  end

  def render("show.json", %{media: media}) do
    %{data: render_one(media, MediaView, "media.json")}
  end

  def render("media.json", %{media: media}) do
    %{
      id: media.id,
      artist_id: media.artist_id,
      work_id: media.work_id,
      title: media.title,
      caption: media.caption,
      src: "/media/" <> media.filename,
      content_type: media.content_type
    }
  end
end
