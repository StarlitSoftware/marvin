defmodule Hub.PageController do
  use Hub.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
