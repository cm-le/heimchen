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

	def search(conn, %{"name" => name}, _user) do
		places = Heimchen.Place.search(name)
		render(conn, "search.html", layout: {Heimchen.LayoutView, "empty.html"}, places: places)
	end


	def add_keyword(conn, %{"id" => id, "keyword" => keyword}, user) do
		case Repo.insert(PlaceKeyword.changeset(%PlaceKeyword{},
							%{"keyword_id" => Heimchen.Keyword.id_by_cat_name(keyword), "place_id" => id}, user)) do
			{:ok, _} ->
				conn
				|> put_flash(:success, "Stichwort hinzugefügt")
				|> redirect(to: place_path(conn, :show, id))
			{:error, _ } ->
				conn
				|> put_flash(:error, "Stichwort konnte nicht hinzugefügt werden")
				|> redirect(to: place_path(conn, :show, id))
		end
	end


	def delete_keyword(conn, %{"id" => id, "keyword_id" => keyword_id}, _) do
		case Repo.get_by(PlaceKeyword, place_id: id, keyword_id: keyword_id) do
			nil ->
				conn |> put_flash(:error, "Stichwort nicht gefunden") |>
					redirect(to: place_path(conn, :index))
			pk ->
				Repo.delete(pk)
				conn |> put_flash(:success, "Stichwort gelöscht") |>
					redirect(to: place_path(conn, :show, pk.place_id))
		end
	end

	def show(conn, %{"id" => id}, _user) do
		case Repo.get(Place,id)
		|> Repo.preload([:user, :keywords,
										 imagetags: :image,
										 places_items: [item: :itemtype],
										 places_people: :person]) do
			nil -> conn |> put_flash(:error, "Ort nicht gefunden") |> redirect(to: place_path(conn, :index))
			place -> conn |> render("show.html", place: place, id: id)
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
