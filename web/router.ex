defmodule Marvin.Router do
  use Marvin.Web, :router

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

  scope "/", Marvin do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api", Marvin do
    pipe_through :api

    post "/marvin/percept", PerceptionController, :handle_percept
  end

end
