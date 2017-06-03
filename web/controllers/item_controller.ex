defmodule Heimchen.ItemController do
	use Heimchen.Web, :controller

	alias Heimchen.Item
	alias Heimchen.ItemKeyword
	alias Heimchen.PlaceItem
	
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
		render(conn, "index.html", [items: Item.recently_updated()])
	end


	def mark_item(conn, %{"id" => id}, _user) do
		conn
		|> put_session(:marked_item, id)
		|> put_flash(:success, "Sammlungs-Stück zum zusammenführen vorgemerkt")
		|> redirect(to: item_path(conn, :show, id))
	end

	
	def merge_item(conn, %{"id" => id, "doit" => "0"}, _user) do
		conn
		|> render("merge_item.html",
			item1: Heimchen.Repo.get(Heimchen.Item, get_session(conn, :marked_item)),
			item2: Heimchen.Repo.get(Heimchen.Item, id))
	end

	
	def merge_item(conn, %{"id" => id, "doit" => "1"}, _user) do
		{id1, _} = Integer.parse(id)
		{id2, _} = Integer.parse(get_session(conn, :marked_item))
		Ecto.Adapters.SQL.query(Heimchen.Repo,
			"select * from merge_items($1,$2)",	[id1, id2])
		conn
		|> put_session(:marked_item, nil)
		|> put_flash(:success, "Sammlungs-Stücke zusammengeführt")
		|> redirect(to: item_path(conn, :show, id))
	end

	
	def show(conn, %{"id" => id}, _user) do
		case Repo.get(Item,id)
		|> Repo.preload([:user, :itemtype, :received_by, :room, :keywords,
										 imagetags: [image: :imagetags], places_items: :place]) do
			nil -> conn |> put_flash(:error, "Eintrag nicht gefunden") |> redirect(to: item_path(conn, :index))
			item -> conn |> render("show.html", item: item, id: id,
			                       marked: get_session(conn, :marked_item),
			                       skiplist: Item.skiplist(item))
		end
	end

	def edit(conn, %{"id" => id}, user) do
		render(conn, "edit.html",
			itemtypes: Repo.all(Heimchen.Itemtype),
			people: Repo.all(Heimchen.Person, order_by: [:lastname, :firstname]),
			rooms: Repo.all(Heimchen.Room, order_by: [:name]),
			changeset: Item.changeset(Repo.get(Item,id) |> Repo.preload([:user, :itemtype, :received_by, :room, :keywords, imagetags: :image]), :invalid, user),
			id: id)
	end

	def new(conn, _params, user) do
		render(conn, "new.html",
			itemtypes: Repo.all(Heimchen.Itemtype),
			people: Repo.all(Heimchen.Person, order_by: [:lastname, :firstname]),
			rooms: Repo.all(Heimchen.Room, order_by: [:name]),
			changeset: Item.changeset(%Item{}, :invalid, user))
	end
	
	def create(conn, %{"item" => item_params}, user) do
		changeset = Item.changeset(%Item{}, item_params, user)
		case Repo.insert(changeset) do
			{:ok, item} ->
				conn
				|> put_flash(:success, "Eintrag angelegt")
				|> redirect(to: item_path(conn, :show, item.id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Eintrag konnte nicht angelegt werden")
				|> render("new.html", changeset: changeset,	itemtypes: Repo.all(Heimchen.Itemtype),
					people: Repo.all(Heimchen.Person, order_by: [:lastname, :firstname]),
					rooms: Repo.all(Heimchen.Room, order_by: [:name]))
		end
	end

	
	def update(conn, %{"id" => id, "item" => item_params}, user) do
		changeset = Item.changeset(Repo.get(Item, id), item_params, user)
		case Repo.update(changeset) do
			{:ok, item} ->
				conn
				|> put_flash(:success, "Eintrag #{item.name} geändert")
				|> redirect(to: item_path(conn, :show, id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Eintrag konnte nicht geändert werden")
				|> render("edit.html", changeset: changeset, 			itemtypes: Repo.all(Heimchen.Itemtype),
					people: Repo.all(Heimchen.Person, order_by: [:lastname, :firstname]),
					rooms: Repo.all(Heimchen.Room, order_by: [:name]),
					id: id)
		end
	end


	def delete_keyword(conn, %{"item_id" => item_id, "keyword_id" => keyword_id}, _) do
		case Repo.get_by(ItemKeyword, item_id: item_id, keyword_id: keyword_id) do
			nil ->
				conn |> put_flash(:error, "Stichwort nicht gefunden") |>
					redirect(to: item_path(conn, :index))
			ik ->
				Repo.delete(ik)
				conn |> put_flash(:success, "Stichwort gelöscht") |> redirect(to: item_path(conn, :show, ik.item_id))
		end
	end

	def add_place(conn, %{"pi" => pi}, user) do
		changeset = PlaceItem.changeset(%PlaceItem{}, pi, user)
		case Repo.insert(changeset) do
			{:ok, pi} ->
				conn
				|> put_flash(:success, "Verknüpfung angelegt")
				|> redirect(to: item_path(conn, :show, pi.item_id))
			_ ->
				conn
				|> put_flash(:error, "Verknüpfung konnte nicht angelegt werden")
				|> redirect(to: item_path(conn, :show, pi.item_id))
		end
	end

	def delete_place(conn, %{"id" => id}, _) do
		case Repo.get(Heimchen.PlaceItem, id) do
			nil ->
				conn |> put_flash(:error, "Ort nicht gefunden") |>
					redirect(to: person_path(conn, :index))
			pi ->
				Repo.delete(pi)
				conn |> put_flash(:success, "Ort-Verknüpfung gelöscht") |>
					redirect(to: item_path(conn, :show, pi.item_id))
		end
	end
	
end
