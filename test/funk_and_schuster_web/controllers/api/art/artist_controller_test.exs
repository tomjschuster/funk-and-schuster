defmodule FunkAndSchusterWeb.Api.Art.ArtistControllerTest do
  use FunkAndSchusterWeb.ConnCase

  alias FunkAndSchuster.Api.Art
  alias FunkAndSchuster.Api.Art.Artist

  @create_attrs %{
    dob: 42,
    first_name: "some first_name",
    last_name: "some last_name"
  }
  @update_attrs %{
    dob: 43,
    first_name: "some updated first_name",
    last_name: "some updated last_name"
  }
  @invalid_attrs %{dob: nil, first_name: nil, last_name: nil}

  def fixture(:artist) do
    {:ok, artist} = Art.create_artist(@create_attrs)
    artist
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all artists", %{conn: conn} do
      conn = get(conn, Routes.api_art_artist_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create artist" do
    test "renders artist when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_art_artist_path(conn, :create), artist: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.api_art_artist_path(conn, :show, id))

      assert %{
               "id" => id,
               "dob" => 42,
               "first_name" => "some first_name",
               "last_name" => "some last_name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_art_artist_path(conn, :create), artist: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update artist" do
    setup [:create_artist]

    test "renders artist when data is valid", %{conn: conn, artist: %Artist{id: id} = artist} do
      conn = put(conn, Routes.api_art_artist_path(conn, :update, artist), artist: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.api_art_artist_path(conn, :show, id))

      assert %{
               "id" => id,
               "dob" => 43,
               "first_name" => "some updated first_name",
               "last_name" => "some updated last_name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, artist: artist} do
      conn = put(conn, Routes.api_art_artist_path(conn, :update, artist), artist: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete artist" do
    setup [:create_artist]

    test "deletes chosen artist", %{conn: conn, artist: artist} do
      conn = delete(conn, Routes.api_art_artist_path(conn, :delete, artist))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.api_art_artist_path(conn, :show, artist))
      end
    end
  end

  defp create_artist(_) do
    artist = fixture(:artist)
    {:ok, artist: artist}
  end
end
