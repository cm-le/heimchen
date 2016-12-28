defmodule Heimchen.PageController do
  use Heimchen.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
