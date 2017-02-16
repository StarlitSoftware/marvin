defmodule Marvin.PageController do
  use Marvin.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
