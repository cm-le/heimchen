defmodule Heimchen.KeywordController do
	use Heimchen.Web, :controller

	alias Heimchen.Keyword
	
	plug :authenticate_admin
	plug :load_categories
	
	defp authenticate_admin(conn, _opts) do
		if conn.assigns.current_user && conn.assigns.current_user.admin do
			conn
		else
			conn
			|> put_flash(:error, if conn.assigns.current_user do
						"Sie haben keine Administrator-Rechte"
					else
						"Sie sind nicht eingeloggt / Die Sitzung ist abgelaufen"
					end)
			|> redirect(to: session_path(conn, :new))
			|> halt()
		end
	end

	defp load_categories(conn, _opts) do
		assign(conn, :categories, Keyword.categories)
	end
	
	
	# add user as an additional parameter to every action
	def action(conn, _) do
		apply(__MODULE__, action_name(conn),
			[conn, conn.params, conn.assigns.current_user])
	end
	
	def index(conn, _params, _user) do
		keywords = Repo.all from k in Keyword, left_join: u in assoc(k, :user),
			select: %{keyword: k, user: u},
			order_by: [k.category, k.name]
		render conn, "index.html", keywords: keywords
	end


	def keywords(conn, %{"for" => f}, _) do
		json conn, ((from k in Keyword,
			where: ((^f == "person" and k.for_person) or
			        (^f=="THING" and k.for_thing_item) or
			        (^f=="EVENT" and k.for_event_item) or
			        (^f=="FILM" and k.for_film_item) or
			        (^f=="PHOTO" and k.for_photo_item)), 
			select: %{c: k.category, n: k.name}, order_by: [k.category, k.name])
			|> Repo.all |> Enum.map(&(&1.c <> ": " <> &1.n)))
	end
	
	def edit(conn, %{"id" => id}, user) do
		render(conn, "show.html", changeset: Keyword.changeset(Repo.get(Keyword,id), :invalid, user),
			id: id)
	end


	def show(conn, %{"id" => id}, user) do
		render(conn, "show.html",
			  				 keyword: Repo.get(Keyword,id) |> Repo.preload([:people, :items, :user]),
								 id: id)
	end


	def new(conn, _params, user) do
		render(conn, "new.html", changeset: Keyword.changeset(%Keyword{}, :invalid, user))
	end

	def create(conn, %{"keyword" => keyword_params}, user) do
		changeset = Keyword.changeset(%Keyword{}, keyword_params, user)
		case Repo.insert(changeset) do
			{:ok, keyword} ->
				conn
				|> put_flash(:success, "Stichwort #{keyword.name} angelegt")
				|> redirect(to: keyword_path(conn, :index))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Stichwort konnte nicht angelegt werden")
				|> render("new.html", changeset: changeset)
		end
	end

	def update(conn, %{"id" => id, "keyword" => keyword_params}, user) do
		changeset = Keyword.changeset(Repo.get(Keyword, id), keyword_params, user)
		case Repo.update(changeset) do
			{:ok, keyword} ->
				conn
				|> put_flash(:success, "Stichwort #{keyword.name} geändert")
				|> redirect(to: keyword_path(conn, :index))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Stichwort konnte nicht geändert werden")
				|> render("show.html", changeset: changeset, id: id)
		end
	end
	
end
