require IEx
defmodule Heimchen.PersonController do
	use Heimchen.Web, :controller

	alias Heimchen.Person
	alias Heimchen.PlacePerson
	alias Heimchen.Relative
	
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

	def delete_keyword(conn, %{"person_id" => person_id, "keyword_id" => keyword_id}, _) do
		case Repo.get_by(Heimchen.PersonKeyword, person_id: person_id, keyword_id: keyword_id) do
			nil ->
				conn |> put_flash(:error, "Stichwort nicht gefunden") |>
					redirect(to: person_path(conn, :index))
			pk ->
				Repo.delete(pk)
				conn |> put_flash(:success, "Stichwort gelöscht") |>
					redirect(to: person_path(conn, :show, person_id))
		end
	end


	def delete_place(conn, %{"id" => id}, _) do
		case Repo.get(Heimchen.PlacePerson, id) do
			nil ->
				conn |> put_flash(:error, "Ort nicht gefunden") |>
					redirect(to: person_path(conn, :index))
			pp ->
				Repo.delete(pp)
				conn |> put_flash(:success, "Ort-Verknüpfung gelöscht") |>
					redirect(to: person_path(conn, :show, pp.person_id))
		end
	end


	def mark_person(conn, %{"id" => id}, _user) do
		conn
		|> put_session(:marked_person, id)
		|> put_flash(:success, "Person zum zusammenführen vorgemerkt")
		|> redirect(to: person_path(conn, :show, id))
	end

	def merge_person(conn, %{"id" => id, "doit" => "0"}, _user) do
		conn
		|> render("merge_person.html",
			person1: Heimchen.Repo.get(Heimchen.Person, get_session(conn, :marked_person)),
			person2: Heimchen.Repo.get(Heimchen.Person, id))
	end

	def merge_person(conn, %{"id" => id, "doit" => "1"}, _user) do
		{id1, _} = Integer.parse(id)
		{id2, _} = Integer.parse(get_session(conn, :marked_person))
		Ecto.Adapters.SQL.query(Heimchen.Repo,
			"select * from merge_people($1,$2)",[id1, id2])
		conn
		|> put_session(:marked_person, nil)
		|> put_flash(:success, "Personen zusammengeführt")
		|> redirect(to: person_path(conn, :show, id))
	end

	
	def show(conn, %{"id" => id}, _user) do
		case Repo.get(Person,id)
		|> Repo.preload([:user, :keywords, imagetags: [image: :imagetags],
										 items: :itemtype, places_people: :place]) do
			nil -> conn |> put_flash(:error, "Person nicht gefunden") |> redirect(to: person_path(conn, :index))
			person ->
				conn
				|> render("show.html", person: person, id: id, marked: get_session(conn, :marked_person),
					skiplist: Person.skiplist(person), relatives: Person.relatives(person))
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

	def add_place(conn, %{"pp" => pp}, user) do
		changeset = PlacePerson.changeset(%PlacePerson{}, pp, user)
		case Repo.insert(changeset) do
			{:ok, pp} ->
				conn
				|> put_flash(:success, "Verknüpfung angelegt")
				|> redirect(to: person_path(conn, :show, pp["person_id"]))
			_ ->
				conn
				|> put_flash(:error, "Verknüpfung konnte nicht angelegt werden")
				|> redirect(to: person_path(conn, :show, pp["person_id"]))
		end
	end

	def add_relative(conn, %{"ar" => ar}, user) do
		changeset = Relative.changeset(%Relative{}, ar, user)
		case Repo.insert(changeset) do
			{:ok, pp} ->
				conn
				|> put_flash(:success, "Verknüpfung angelegt")
				|> redirect(to: person_path(conn, :show, ar["person1_id"]))
			_ ->
				conn
				|> put_flash(:error, "Verknüpfung konnte nicht angelegt werden")
				|> redirect(to: person_path(conn, :show, ar["person2_id"]))
		end
	end


	def del_relative(conn, %{"id" => id, "person_id" => person_id}, user) do
		Repo.delete(Repo.get(Relative,id))
		conn
		|> put_flash(:success, "Beziehung gelöscht")
		|> redirect(to: person_path(conn, :show, person_id))
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
