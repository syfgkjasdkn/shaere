defmodule Web.Router do
  @moduledoc false
  use Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", Web.Plugs do
    pipe_through(:api)

    forward("/tgbot", TGBot)
  end
end
