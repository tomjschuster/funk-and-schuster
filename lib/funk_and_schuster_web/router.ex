defmodule FunkAndSchusterWeb.Router do
  use FunkAndSchusterWeb, :router
  alias FunkAndSchusterWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :art do
    plug Plugs.RequireAdmin
  end

  scope "/", FunkAndSchusterWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/about", PageController, :about
    get "/gallery", PageController, :gallery
    get "/process", PageController, :process
    get "/contact", PageController, :contact

    get "/media/:filename", FileController, :show
  end

  scope "/art", FunkAndSchusterWeb.Art do
    pipe_through :browser
    pipe_through :art

    get "/", ArtController, :index

    resources "/artists", ArtistController do
      resources "/works", WorkController do
        resources "/media", MediaController
      end

      resources "/media", MediaController
    end

    resources "/works", WorkController do
      resources "/media", MediaController
    end

    resources "/media", MediaController

    resources "/galleries", GalleryController
    post "/galleries/:id/feature", GalleryController, :feature
  end

  scope "/api/art", FunkAndSchusterWeb.Art do
    pipe_through :api
    pipe_through :art

    resources "/artists", Api.ArtistController
    resources "/works", Api.WorkController
    resources "/media", Api.MediaController
  end
end
