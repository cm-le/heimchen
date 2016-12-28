defmodule Heimchen.ItemController do
	use Heimchen.Web, :controller

	def index(conn, _) do
		render(conn, "index.html", [])
	end
	
end
