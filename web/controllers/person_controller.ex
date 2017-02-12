require IEx
defmodule Heimchen.PersonController do
	use Heimchen.Web, :controller

	alias Heimchen.Person
	alias Heimchen.PersonKeyword
	
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
	
	# add user as an additional parameter to every action
	def action(conn, _) do
		apply(__MODULE__, action_name(conn),
			[conn, conn.params, conn.assigns.current_user])
	end
	
	def index(conn, _params, _user) do
		render(conn, "index.html", [people: Heimchen.Person.recently_updated()])
	end

	def search(conn, %{"name" => name}, _user) do
		people = Heimchen.Person.search(name)
		render(conn, "search.html", layout: {Heimchen.LayoutView, "empty.html"}, people: people)
	end


	def add_keyword(conn, %{"id" => id, "keyword" => keyword}, user) do
		case Repo.insert(PersonKeyword.changeset(%PersonKeyword{},
							%{"keyword_id" => Heimchen.Keyword.id_by_cat_name(keyword), "person_id" => id}, user)) do
			{:ok, _} ->
				conn
				|> put_flash(:success, "Stichwort hinzugefügt")
				|> redirect(to: person_path(conn, :show, id))
			{:error, _ } ->
				conn
				|> put_flash(:error, "Stichwort konnte nicht hinzugefügt werden")
				|> redirect(to: person_path(conn, :show, id))
		end
	end


	def delete_keyword(conn, %{"id" => id}, _) do
		case Repo.get(Heimchen.PersonKeyword, id) do
			nil ->
				conn |> put_flash(:error, "Stichwort nicht gefunden") |>
					redirect(to: person_path(conn, :index))
			pk ->
				Repo.delete(pk)
				conn |> put_flash(:success, "Stichwort gelöscht") |> redirect(to: person_path(conn, :show, pk.person_id))
		end
	end

	def show(conn, %{"id" => id}, _user) do
		case Repo.get(Person,id) |> Repo.preload([:user, imagetags: :image]) do
			nil -> conn |> put_flash(:error, "Person nicht gefunden") |> redirect(to: person_path(conn, :index))
			person -> conn |> render("show.html", person: person, id: id, keywords: Person.keywords(person))
		end
	end

	def edit(conn, %{"id" => id}, user) do
		render(conn, "edit.html", changeset: Person.changeset(Repo.get(Person,id), :invalid, user),
			id: id)
	end
	
	def new(conn, _params, user) do
		render(conn, "new.html", changeset: Person.changeset(%Person{}, :invalid, user))
	end

	def create(conn, %{"person" => person_params}, user) do
		changeset = Person.changeset(%Person{}, person_params, user)
		case Repo.insert(changeset) do
			{:ok, person} ->
				conn
				|> put_flash(:success, "Person angelegt")
				|> redirect(to: person_path(conn, :show, person.id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Person konnte nicht angelegt werden")
				|> render("new.html", changeset: changeset)
		end
	end

	def update(conn, %{"id" => id, "person" => person_params}, user) do
		changeset = Person.changeset(Repo.get(Person, id), person_params, user)
		case Repo.update(changeset) do
			{:ok, person} ->
				conn
				|> put_flash(:success, "Person #{Person.name(person)} geändert")
				|> redirect(to: person_path(conn, :show, id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Person konnte nicht geändert werden")
				|> render("show.html", changeset: changeset, id: id)
		end
	end
	
end
