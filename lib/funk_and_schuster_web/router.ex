defmodule FunkAndSchusterWeb.Router do
  use FunkAndSchusterWeb, :router

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

  scope "/", FunkAndSchusterWeb do
    # Use the default browser stack
    pipe_through :browser

    get "/", PageController, :index
    get "/about", PageController, :about
    get "/gallery", PageController, :gallery
    get "/process", PageController, :process
    get "/contact", PageController, :contact

    resources "/artists", ArtistController do
      resources "/works", WorkController
    end

    get "/media/:filename", MediaController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", FunkAndSchusterWeb do
  #   pipe_through :api
  # end
end
