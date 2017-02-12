require IEx
defmodule Heimchen.ImageController do
	use Heimchen.Web, :controller

	plug :authenticate

	defp authenticate(conn, _opts) do
		if !get_session(conn, :image_clipboard) do
			conn = conn |> put_session(:image_clipboard, %{})
		end
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

	############
	
	def index(conn, _params, _user) do
		render(conn, "index.html", [images: Heimchen.Image.recently_uploaded(),
																clipboard: get_session(conn, :image_clipboard)])
	end

	def new(conn, _params, _user) do
		render(conn, "new.html", [])
	end

	def image(conn, %{"id" => id, "size" => size}, _user) do
		case Repo.get(Heimchen.Image, id) do
			nil -> resp(conn, 404, "Not found")
			image -> 
				send_file(conn, 200, Heimchen.Image.delayed_dir(image) <> "/" <>
					%{"1" => "thumb.jpg",
        		"2" => "medium.jpg",
        		"3" => "large.jpg",
        		"4" => Heimchen.Image.orig_name(image)}[size]) 
		end
	end
	
	def create(conn, %{"upload" => upload_params}, user) do
		images = Heimchen.Image.create(upload_params, user)
		conn
		|> put_session(:image_clipboard,
			Map.merge(get_session(conn, :image_clipboard), Map.new(images, fn i -> {i.id, true} end)))
		|> put_flash(:success, "#{length(images)} Bild(er) wurde hochgeladen")
		|> redirect(to: image_path(conn, :index))
	end

	def show(conn, %{"id" => id}, user) do
		case Repo.get(Heimchen.Image, id) do
			nil ->
				conn
				|>put_flash(:error, "Bild nicht gefunden, wurde es gerade gelöscht?")
				|> redirect(to: image_path(conn, :index))
			image ->
				conn
				|> render("show.html",
					[id: id, clipboard_n: length(Map.keys(get_session(conn, :image_clipboard))),
					 changeset: Heimchen.Image.changeset(image |> Repo.preload(imagetags: :person), :invalid)])
		end
	end	


	def update(conn, %{"id" => id, "image" => image_params}, user) do
		changeset = Image.changeset(Repo.get(Heimchen.Image, id), image_params, user)
		case Repo.update(changeset) do
			{:ok, image} ->
				conn
				|> put_flash(:success, "Bild #{image.original_filename} geändert")
				|> redirect(to: image_path(conn, :show, id))
				{:error ,changeset}
				conn
				|> put_flash(:error, "Person konnte nicht geändert werden")
				|> render("show.html", changeset: changeset, id: id)
		end
	end

	def mark(conn, %{"what" => "add", "id" => id}, user) do
		conn
		|> put_session(:image_clipboard,
			Map.merge(get_session(conn, :image_clipboard), %{String.to_integer(id) => true}))
		|> json "ok"
	end

	def mark(conn, %{"what" => "rm", "id" => id}, user) do
		conn
		|> put_session(:image_clipboard,
			Map.delete(get_session(conn, :image_clipboard), String.to_integer(id)))
		|> json "ok"
	end

	def marklist(conn, _, _user) do
		conn |> json Heimchen.Imagetag.marklist()
	end

	def add_and_show_clipboard(conn, %{"id" => id}, _user) do
		conn
		|> put_session(:image_clipboard,
			Map.merge(get_session(conn, :image_clipboard), %{String.to_integer(id) => true}))
		|> redirect(to: image_path(conn, :clipboard))
	end

	def clipboard(conn, _, _user) do
		ids = Map.keys(get_session(conn, :image_clipboard))
		conn
		|> render("clipboard.html",
			[images: Heimchen.Repo.all(from i in Heimchen.Image,
					where: fragment("id = any(?)", ^ids),preload: [imagetags: :person])])
	end


	def clipboard_mark(conn, %{"mark" => mark}, user) do
		imageids = Map.keys(get_session(conn, :image_clipboard))
		c = Heimchen.Imagetag.create_from_marklist(imageids, mark, user)
		conn
		|> put_flash(:success, "#{c} Bilder neu markiert")
		|> redirect(to: image_path(conn, :clipboard))
	end

	def clipboard_empty(conn, _, _user) do
		conn
		|> put_flash(:success, "Zwischenablage geleert")
		|> put_session(:image_clipboard, %{})
		|> redirect(to: image_path(conn, :index))
	end
	
	def del_imagetag(conn, %{"id" => id}, user) do
		it = Heimchen.Repo.get(Heimchen.Imagetag,id)
		Heimchen.Repo.delete(it)
		conn
		|> redirect(to: person_path(conn, :show, it.person_id))
	end 
	
end
