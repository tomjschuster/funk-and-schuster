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

    get "/media/:filename", Art.MediaController, :show
  end

  scope "/art", FunkAndSchusterWeb.Art do
    pipe_through :browser
    pipe_through :art

    resources "/artists", ArtistController do
      resources "/works", WorkController
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", FunkAndSchusterWeb do
  #   pipe_through :api
  # end
end
