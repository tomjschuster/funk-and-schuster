defmodule FunkAndSchusterWeb.Api.Art.WorkController do
  use FunkAndSchusterWeb, :controller

  alias FunkAndSchuster.ArtApi
  alias FunkAndSchuster.Art.Work

  action_fallback FunkAndSchusterWeb.FallbackController

  def index(conn, _params) do
    works = ArtApi.list_works()
    render(conn, "index.json", works: works)
  end

  def create(conn, %{"work" => work_params}) do
    files = []

    with {:ok, %{work: %Work{} = work}} <- ArtApi.create_work(work_params, files) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", Routes.api_art_work_path(conn, :show, work))
      |> render("id.json", work: work)
    end
  end

  def show(conn, %{"id" => id}) do
    work = ArtApi.get_work!(id)
    render(conn, "show.json", work: work)
  end

  def update(conn, %{"id" => id, "work" => work_params}) do
    files = []
    work = ArtApi.get_work!(id)

    with {:ok, %Work{} = work} <- ArtApi.update_work(work, work_params, files) do
      render(conn, "show.json", work: work)
    end
  end

  def delete(conn, %{"id" => _id}) do
    # work = ArtApi.get_work!(id)

    # with {:ok, %Work{}} <- ArtApi.delete_work(work) do
    send_resp(conn, :no_content, "")
    # end
  end
end
