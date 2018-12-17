defmodule FunkAndSchusterWeb.Art.MediaControllerTest do
  use FunkAndSchusterWeb.ConnCase

  alias FunkAndSchuster.Art

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:media) do
    {:ok, media} = Art.create_media(@create_attrs)
    media
  end

  describe "index" do
    test "lists all media", %{conn: conn} do
      conn = get conn, art_media_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Media"
    end
  end

  describe "new media" do
    test "renders form", %{conn: conn} do
      conn = get conn, art_media_path(conn, :new)
      assert html_response(conn, 200) =~ "New Media"
    end
  end

  describe "create media" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, art_media_path(conn, :create), media: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == art_media_path(conn, :show, id)

      conn = get conn, art_media_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Media"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, art_media_path(conn, :create), media: @invalid_attrs
      assert html_response(conn, 200) =~ "New Media"
    end
  end

  describe "edit media" do
    setup [:create_media]

    test "renders form for editing chosen media", %{conn: conn, media: media} do
      conn = get conn, art_media_path(conn, :edit, media)
      assert html_response(conn, 200) =~ "Edit Media"
    end
  end

  describe "update media" do
    setup [:create_media]

    test "redirects when data is valid", %{conn: conn, media: media} do
      conn = put conn, art_media_path(conn, :update, media), media: @update_attrs
      assert redirected_to(conn) == art_media_path(conn, :show, media)

      conn = get conn, art_media_path(conn, :show, media)
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, media: media} do
      conn = put conn, art_media_path(conn, :update, media), media: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Media"
    end
  end

  describe "delete media" do
    setup [:create_media]

    test "deletes chosen media", %{conn: conn, media: media} do
      conn = delete conn, art_media_path(conn, :delete, media)
      assert redirected_to(conn) == art_media_path(conn, :index)

      assert_error_sent 404, fn ->
        get conn, art_media_path(conn, :show, media)
      end
    end
  end

  defp create_media(_) do
    media = fixture(:media)
    {:ok, media: media}
  end
end
