defmodule FunkAndSchusterWeb.Art.GalleryControllerTest do
  use FunkAndSchusterWeb.ConnCase

  alias FunkAndSchuster.Art

  @create_attrs %{title: "some title"}
  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  def fixture(:gallery) do
    {:ok, gallery} = Art.create_gallery(@create_attrs)
    gallery
  end

  describe "index" do
    test "lists all galleries", %{conn: conn} do
      conn = get conn, art_gallery_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Galleries"
    end
  end

  describe "new gallery" do
    test "renders form", %{conn: conn} do
      conn = get conn, art_gallery_path(conn, :new)
      assert html_response(conn, 200) =~ "New Gallery"
    end
  end

  describe "create gallery" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, art_gallery_path(conn, :create), gallery: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == art_gallery_path(conn, :show, id)

      conn = get conn, art_gallery_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Gallery"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, art_gallery_path(conn, :create), gallery: @invalid_attrs
      assert html_response(conn, 200) =~ "New Gallery"
    end
  end

  describe "edit gallery" do
    setup [:create_gallery]

    test "renders form for editing chosen gallery", %{conn: conn, gallery: gallery} do
      conn = get conn, art_gallery_path(conn, :edit, gallery)
      assert html_response(conn, 200) =~ "Edit Gallery"
    end
  end

  describe "update gallery" do
    setup [:create_gallery]

    test "redirects when data is valid", %{conn: conn, gallery: gallery} do
      conn = put conn, art_gallery_path(conn, :update, gallery), gallery: @update_attrs
      assert redirected_to(conn) == art_gallery_path(conn, :show, gallery)

      conn = get conn, art_gallery_path(conn, :show, gallery)
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, gallery: gallery} do
      conn = put conn, art_gallery_path(conn, :update, gallery), gallery: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Gallery"
    end
  end

  describe "delete gallery" do
    setup [:create_gallery]

    test "deletes chosen gallery", %{conn: conn, gallery: gallery} do
      conn = delete conn, art_gallery_path(conn, :delete, gallery)
      assert redirected_to(conn) == art_gallery_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, art_gallery_path(conn, :show, gallery)
      end
    end
  end

  defp create_gallery(_) do
    gallery = fixture(:gallery)
    {:ok, gallery: gallery}
  end
end
