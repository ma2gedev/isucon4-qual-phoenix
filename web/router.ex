defmodule Isucon4.Router do
  use Isucon4.Web, :router

  pipeline :browser do
    plug PlugForwardedPeer
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    #plug :protect_from_forgery for isucon4 benchmarker
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Isucon4 do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    post "/login", PageController, :login
    get "/mypage", PageController, :mypage
  end

  scope "/", Isucon4 do
    pipe_through :api

    get "/report", PageController, :report
  end
end
