defmodule Pxblog.Router do
  use Pxblog.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    #plug :scrub_params, "user" when action in [:create]
  end

  scope "/", Pxblog do
    pipe_through :browser # Use the default browser stack

    resources "/users", UserController do
      resources "/posts", PostController do
        resources "/comments", CommentController, only: [:create, :delete, :show, :update]
      end
    end

    resources "/sessions", SessionController, only: [:new, :create, :delete]
    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", Pxblog do
  #   pipe_through :api
  # end
end
