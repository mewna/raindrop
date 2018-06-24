defmodule RaindropWeb.ApiController do
  use RaindropWeb, :controller

  def gen_snowflake(conn, _params) do
   << snowflake::integer-size(64) >> = Raindrop.Generator.gen_drop
    conn |> text(snowflake)
  end
end