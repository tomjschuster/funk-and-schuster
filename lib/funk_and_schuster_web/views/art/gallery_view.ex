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
      checked? = not is_nil(gallery_media_id)

      value = Poison.encode!(%{id: gallery_media_id, media_id: m.id, checked?: checked?})
      checked_value = Poison.encode!(%{id: gallery_media_id, media_id: m.id, checked?: true})
      unchecked_value = Poison.encode!(%{id: gallery_media_id, media_id: m.id, checked?: false})

      [
        label class: "control-label", for: "media-#{m.id}" do
          img_tag("/media/#{m.filename}", style: "width: 50px; height: 50px")
        end,
        checkbox(form, :gallery_media,
          class: "form-control",
          id: "media-#{m.id}",
          name: "gallery_media[]",
          checked_value: checked_value,
          unchecked_value: unchecked_value,
          value: value
        )
      ]

      # end
    end)
  end
end
