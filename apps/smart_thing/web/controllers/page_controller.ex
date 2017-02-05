defmodule SmartThing.PageController do
  use SmartThing.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
