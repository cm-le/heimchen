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
							keywords:  Enum.map(keywords || [],
                fn %{"category" => c, "id" => id, "name" => n} ->
									%{category: c, id: id, name: n} end),
							image_id: image_id} end),
					headline: "Suchergebnisse")
			_ ->
				render(conn, "index.html", layout: {Heimchen.LayoutView, "empty.html"},
					results: [], headline: "Suchergebnisse")
		end
  end		


	def personlist(conn, %{}) do
		live = fn (p) ->
						 if p.born_on do
							 p.born_on.year
						 else
							 "-"
						 end
		end
		plist =
		(Heimchen.Repo.all(Heimchen.Person, order_by: [:lastname, :firstname]) |>
			Heimchen.Repo.preload([[imagetags: :image], :keywords])) |>
			Enum.map(fn p -> "\\Person{#{p.lastname}}{#{p.firstname}}{#{live.(p)}}{#{p.comment}}{" <>
				(Enum.slice(p.imagetags,0,3) |>
					Enum.map(fn it -> "\\Image{" <> Heimchen.Image.dir(it.image) <> "/thumb.jpg}" end)
					|> Enum.join()) <>
											 
					"}\n" end) 	|>
			Enum.join()
		{_, t} = Phoenix.View.render(Heimchen.SearchView, "personlist.html", plist: plist)
		dir = Application.get_env(:heimchen, :uploads)
		{:ok, file} = File.open dir <> "plist.tex" , [:write] # FIXME no parallel plist creation :-(
		IO.binwrite file, t
		File.close file
		System.cmd("pdflatex", ["-interaction", "nonstopmode", file], cd: dir)
		conn
		|> put_resp_content_type("application/octet-stream", nil)
		|> put_resp_header("content-disposition", ~s[attachment; filename="personenliste.pdf"])
		|> send_file(200, dir <> "plist.pdf")
	end
end
