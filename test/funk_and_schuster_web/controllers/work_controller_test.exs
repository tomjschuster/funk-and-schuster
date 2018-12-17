defmodule FunkAndSchusterWeb.WorkControllerTest do
  use FunkAndSchusterWeb.ConnCase

  alias FunkAndSchuster.Art

  @create_attrs %{
    date: ~D[2010-04-17],
    dimensions: "some dimensions",
    medium: "some medium",
    title: "some title"
  }
  @update_attrs %{
    date: ~D[2011-05-18],
    dimensions: "some updated dimensions",
    medium: "some updated medium",
    title: "some updated title"
  }
  @invalid_attrs %{date: nil, dimensions: nil, medium: nil, title: nil}

  def fixture(:work) do
    {:ok, work} = Art.create_work(@create_attrs)
    work
  end

  describe "index" do
    test "lists all works", %{conn: conn} do
      conn = get conn, work_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Works"
    end
  end

  describe "new work" do
    test "renders form", %{conn: conn} do
      conn = get conn, work_path(conn, :new)
      assert html_response(conn, 200) =~ "New Work"
    end
  end

  describe "create work" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, work_path(conn, :create), work: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == work_path(conn, :show, id)

      conn = get conn, work_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Work"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, work_path(conn, :create), work: @invalid_attrs
      assert html_response(conn, 200) =~ "New Work"
    end
  end

  describe "edit work" do
    setup [:create_work]

    test "renders form for editing chosen work", %{conn: conn, work: work} do
      conn = get conn, work_path(conn, :edit, work)
      assert html_response(conn, 200) =~ "Edit Work"
    end
  end

  describe "update work" do
    setup [:create_work]

    test "redirects when data is valid", %{conn: conn, work: work} do
      conn = put conn, work_path(conn, :update, work), work: @update_attrs
      assert redirected_to(conn) == work_path(conn, :show, work)

      conn = get conn, work_path(conn, :show, work)
      assert html_response(conn, 200) =~ "some updated dimensions"
    end

    test "renders errors when data is invalid", %{conn: conn, work: work} do
      conn = put conn, work_path(conn, :update, work), work: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Work"
    end
  end

  describe "delete work" do
    setup [:create_work]

    test "deletes chosen work", %{conn: conn, work: work} do
      conn = delete conn, work_path(conn, :delete, work)
      assert redirected_to(conn) == work_path(conn, :index)

      assert_error_sent 404, fn ->
        get conn, work_path(conn, :show, work)
      end
    end
  end

  defp create_work(_) do
    work = fixture(:work)
    {:ok, work: work}
  end
end
