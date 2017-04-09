defmodule Heimchen.SearchController do
	use Heimchen.Web, :controller

	plug :authenticate

	defp authenticate(conn, _opts) do
		if conn.assigns.current_user do
			conn
		else
			conn
			|> put_flash(:error, "Sie sind nicht eingeloggt / Die Sitzung ist abgelaufen")
			|> redirect(to: session_path(conn, :new))
			|> halt()
		end
	end


	def index(conn, %{"search" => search}) do
    # render the search result based in db function search_all
  end		


end
