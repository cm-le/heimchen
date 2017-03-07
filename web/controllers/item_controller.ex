defmodule Heimchen.ItemController do
	use Heimchen.Web, :controller

	alias Heimchen.Item
	alias Heimchen.ItemKeyword
	
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

	def search(conn, %{"name" => name}, _user) do
		items = Item.search(name)
		render(conn, "search.html", layout: {Heimchen.LayoutView, "empty.html"}, items: items)
	end

	def show(conn, %{"id" => id}, _user) do
		case Repo.get(Item,id) |> Repo.preload([:user, :itemtype, :received_by, :room, :keywords, imagetags: :image]) do
			nil -> conn |> put_flash(:error, "Eintrag nicht gefunden") |> redirect(to: item_path(conn, :index))
			item -> conn |> render("show.html", item: item, id: id)
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


	def add_keyword(conn, %{"id" => id, "keyword" => keyword}, user) do
		case Repo.insert(ItemKeyword.changeset(%ItemKeyword{},
							%{"keyword_id" => Heimchen.Keyword.id_by_cat_name(keyword), "item_id" => id}, user)) do
			{:ok, _} ->
				Heimchen.Item.touch_id!(id, user)
				conn
				|> put_flash(:success, "Stichwort hinzugefügt")
				|> redirect(to: item_path(conn, :show, id))
			{:error, _ } ->
				conn
				|> put_flash(:error, "Stichwort konnte nicht hinzugefügt werden")
				|> redirect(to: item_path(conn, :show, id))
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

	
end
