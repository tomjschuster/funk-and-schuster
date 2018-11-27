defmodule FunkAndSchusterWeb.Art.GalleryView do
  use FunkAndSchusterWeb, :view

  def media_options(media), do: Enum.map(media, &{media_img(&1), &1.id})

  defp media_img(media) do
    # img_tag("/media/#{media.filename}", style: "width: 50px; height: 50px")
    media.title
  end

  def gallery_media_checkboxes(form, media, gallery_media) do
    gallery_media_by_media_id = Enum.into(gallery_media, %{}, &{&1.media_id, &1.id})

    Enum.map(media, fn m ->
      gallery_media_id = Map.get(gallery_media_by_media_id, m.id)

      gallery_media_input =
        hidden_input(form, :gallery_media,
          name: "gallery[gallery_media][#{m.id}][id]",
          value: gallery_media_id
        )

      media_input =
        hidden_input(form, :gallery_media,
          name: "gallery[gallery_media][#{m.id}][media_id]",
          value: m.id
        )

      media_checkbox = [
        label class: "control-label", for: "media-#{m.id}" do
          img_tag("/media/#{m.filename}", style: "width: 50px; height: 50px")
        end,
        checkbox(form, :gallery_media,
          class: "form-control",
          id: "media-#{m.id}",
          name: "gallery[gallery_media][#{m.id}][checked?]",
          value: not is_nil(gallery_media_id)
        )
      ]

      if gallery_media_id do
        [gallery_media_input, media_input] ++ media_checkbox
      else
        [media_input | media_checkbox]
      end

      # end
    end)
  end
end
