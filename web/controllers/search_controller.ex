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
		searchterm = if complete == "1" do search else Regex.replace(~r/(\w+)/u, search, "\\1:* ") end
		case Ecto.Adapters.SQL.query(Heimchen.Repo, "select * from search_all($1, 20)", [searchterm]) do
			{:ok, %{rows: results, num_rows: _}} ->
				render(conn, "index.html", layout: {Heimchen.LayoutView, "empty.html"},
					results: results |> Enum.map(fn [what, id, name, comment, keywords, image_id]  ->
						%{what: what, id: id, name: name, comment: comment,
							keywords: Enum.map(keywords,
								fn k -> case k do
													%{"category" => c, "id" => id, "name" => n} -> %{category: c, id: id, name: n}
													_ ->  k
												end
								end),
							image_id: image_id} end),
					headline: "Suchergebnisse")
			_ ->
				render(conn, "index.html", layout: {Heimchen.LayoutView, "empty.html"},
					results: [], headline: "Suchergebnisse")
		end
  end		


end
