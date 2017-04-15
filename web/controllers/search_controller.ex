require IEx
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


	def index(conn, %{"id" => search, "complete" => complete}) do
		if !(complete == "1") do
			search = Regex.replace(~r/(\w+)/, search, "\\1:* ")
		end
		case Ecto.Adapters.SQL.query(Heimchen.Repo, "select * from search_all($1)", [search]) do
			{:ok, %{rows: results, num_rows: _}} ->
				render(conn, "index.html", layout: {Heimchen.LayoutView, "empty.html"}, results: results)
			_ ->
				render(conn, "index.html", layout: {Heimchen.LayoutView, "empty.html"}, results: [])
		end
  end		


end
