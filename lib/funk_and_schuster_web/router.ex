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
    get "/artwork", PageController, :artwork
    get "/print-with-us", PageController, :print_with_us
    get "/contact", PageController, :contact
  end

  # Other scopes may use custom stacks.
  # scope "/api", FunkAndSchusterWeb do
  #   pipe_through :api
  # end
end
