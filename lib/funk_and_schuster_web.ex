defmodule FunkAndSchusterWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use FunkAndSchusterWeb, :controller
      use FunkAndSchusterWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: FunkAndSchusterWeb
      import Plug.Conn
      import FunkAndSchusterWeb.Router.Helpers
      import FunkAndSchusterWeb.Gettext

      use Thesis.Controller
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/funk_and_schuster_web/templates",
                        namespace: FunkAndSchusterWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import FunkAndSchusterWeb.Router.Helpers
      import FunkAndSchusterWeb.ErrorHelpers
      import FunkAndSchusterWeb.Gettext

      use Thesis.View
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller

      use Thesis.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import FunkAndSchusterWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
