defmodule FunkAndSchusterWeb.Api.Art.MediaControllerTest do
  use FunkAndSchusterWeb.ConnCase

  alias FunkAndSchuster.Api.Art
  alias FunkAndSchuster.Api.Art.Media

  @create_attrs %{
    artist_id: 42,
    caption: "some caption",
    contetn_type: "some contetn_type",
    src: "some src",
    title: "some title",
    work_id: 42
  }
  @update_attrs %{
    artist_id: 43,
    caption: "some updated caption",
    contetn_type: "some updated contetn_type",
    src: "some updated src",
    title: "some updated title",
    work_id: 43
  }
  @invalid_attrs %{artist_id: nil, caption: nil, contetn_type: nil, src: nil, title: nil, work_id: nil}

  def fixture(:media) do
    {:ok, media} = Art.create_media(@create_attrs)
    media
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all media", %{conn: conn} do
      conn = get(conn, Routes.api_art_media_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create media" do
    test "renders media when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_art_media_path(conn, :create), media: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.api_art_media_path(conn, :show, id))

      assert %{
               "id" => id,
               "artist_id" => 42,
               "caption" => "some caption",
               "contetn_type" => "some contetn_type",
               "src" => "some src",
               "title" => "some title",
               "work_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_art_media_path(conn, :create), media: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update media" do
    setup [:create_media]

    test "renders media when data is valid", %{conn: conn, media: %Media{id: id} = media} do
      conn = put(conn, Routes.api_art_media_path(conn, :update, media), media: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.api_art_media_path(conn, :show, id))

      assert %{
               "id" => id,
               "artist_id" => 43,
               "caption" => "some updated caption",
               "contetn_type" => "some updated contetn_type",
               "src" => "some updated src",
               "title" => "some updated title",
               "work_id" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, media: media} do
      conn = put(conn, Routes.api_art_media_path(conn, :update, media), media: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete media" do
    setup [:create_media]

    test "deletes chosen media", %{conn: conn, media: media} do
      conn = delete(conn, Routes.api_art_media_path(conn, :delete, media))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.api_art_media_path(conn, :show, media))
      end
    end
  end

  defp create_media(_) do
    media = fixture(:media)
    {:ok, media: media}
  end
end
