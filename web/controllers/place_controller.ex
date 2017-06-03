require IEx
defmodule Heimchen.PlaceController do
	use Heimchen.Web, :controller
	alias Heimchen.PlaceKeyword
	alias Heimchen.Place
	
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
		render(conn, "index.html", [places: Heimchen.Place.recently_updated()])
	end


	def delete_keyword(conn, %{"place_id" => place_id, "keyword_id" => keyword_id}, _) do
		case Repo.get_by(PlaceKeyword, place_id: place_id, keyword_id: keyword_id) do
			nil ->
				conn |> put_flash(:error, "Stichwort nicht gefunden") |>
					redirect(to: place_path(conn, :index))
			pk ->
				Repo.delete(pk)
				conn |> put_flash(:success, "Stichwort gelöscht") |>
					redirect(to: place_path(conn, :show, pk.place_id))
		end
	end

	def getlatlong(conn, %{"id" => id}, _) do
		p = Repo.get(Place, id)
		case Place.setLatLong(p) do
			{:error} -> conn
				|> put_flash(:error, "Länge/Breite konnte nicht abgefragt werden")
				|> redirect(to: place_path(conn, :show, id))
				_ -> conn
					|> put_flash(:info, "Länge/Breite abgefragt")
					|> redirect(to: place_path(conn, :show, id))
		end
	end

	def mark_place(conn, %{"id" => id}, _user) do
		conn
		|> put_session(:marked_place, id)
		|> put_flash(:success, "Ort zum zusammenführen vorgemerkt")
		|> redirect(to: place_path(conn, :show, id))
	end

	
	def merge_place(conn, %{"id" => id, "doit" => "0"}, _user) do
		conn
		|> render("merge_place.html",
			place1: Heimchen.Repo.get(Heimchen.Place, get_session(conn, :marked_place)),
			place2: Heimchen.Repo.get(Heimchen.Place, id))
	end

	
	def merge_place(conn, %{"id" => id, "doit" => "1"}, _user) do
		Ecto.Adapters.SQL.query(Heimchen.Repo,
			"select * from merge_places($1,$2)",
			[get_session(conn, :marked_place), id])
		conn
		|> put_session(:marked_place, nil)
		|> put_flash(:success, "Orte zusammengeführt")
		|> redirect(to: place_path(conn, :show, id))
	end



	
	def show(conn, %{"id" => id}, _user) do
		case Repo.get(Place,id)
		|> Repo.preload([:user, :keywords,
										 imagetags: [image: :imagetags],
										 places_items: [item: :itemtype],
										 places_people: :person]) do
			nil -> conn |> put_flash(:error, "Ort nicht gefunden") |> redirect(to: place_path(conn, :index))
			place -> conn |> render("show.html", place: place, id: id,
                         			nearby: Place.nearby(place),skiplist: Place.skiplist(place),
			                        marked: get_session(conn, :marked_place),
			                        googleapikey: Application.get_env(:heimchen, :googleapikey) )
		end
	end

	def edit(conn, %{"id" => id}, user) do
		render(conn, "edit.html", changeset: Place.changeset(Repo.get(Place,id), :invalid, user),
			id: id)
	end
	
	def new(conn, _params, user) do
		render(conn, "new.html", changeset: Place.changeset(%Place{}, :invalid, user))
	end

	def create(conn, %{"place" => place_params}, user) do
		changeset = Place.changeset(%Place{}, place_params, user)
		case Repo.insert(changeset) do
			{:ok, place} ->
				conn
				|> put_flash(:success, "Ort angelegt")
				|> redirect(to: place_path(conn, :show, place.id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Ort konnte nicht angelegt werden")
				|> render("new.html", changeset: changeset)
		end
	end

	def update(conn, %{"id" => id, "place" => place_params}, user) do
		changeset = Place.changeset(Repo.get(Place, id), place_params, user)
		case Repo.update(changeset) do
			{:ok, place} ->
				conn
				|> put_flash(:success, "Ort #{place.city}, #{place.address} geändert")
				|> redirect(to: place_path(conn, :show, id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Ort konnte nicht geändert werden")
				|> render("show.html", changeset: changeset, id: id)
		end
	end
	
end
