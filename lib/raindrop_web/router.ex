defmodule RaindropWeb.Router do
  use RaindropWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  get "/", RaindropWeb.ApiController, :gen_snowflake

  scope "/api", RaindropWeb do
    pipe_through :api
  end
end
