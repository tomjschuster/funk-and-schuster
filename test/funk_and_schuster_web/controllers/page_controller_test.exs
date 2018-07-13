defmodule FunkAndSchusterWeb.PageControllerTest do
  use FunkAndSchusterWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Funk and Schuster Fine Art Printing"
  end
end
