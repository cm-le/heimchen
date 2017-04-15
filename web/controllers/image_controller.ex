require IEx
defmodule Heimchen.ImageController do
	use Heimchen.Web, :controller

	plug :authenticate

	defp authenticate(conn, _opts) do
		conn = if !get_session(conn, :image_clipboard) do
			conn |> put_session(:image_clipboard, %{})
		else conn	end
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

	def new(conn, params, _user) do
		item = if (params["item_id"] && String.length(params["item_id"]) > 0) do
			Repo.get(Heimchen.Item, params["item_id"])
		else nil end 
		person = if (params["person_id"]&& String.length(params["person_id"]) > 0) do
			Repo.get(Heimchen.Person, params["person_id"])
		else nil end
		place = if (params["place_id"]&& String.length(params["place_id"]) > 0) do
			Repo.get(Heimchen.Place, params["place_id"])
		else nil end
		render(conn, "new.html", item: item, person: person, place: place,
			item_id: params["item_id"], person_id: params["person_id"], place_id: params["place_id"])
	end

	def delete_all(conn, _user) do
		
	end
	
	def image(conn, %{"id" => id, "size" => size}, _user) do
		case Repo.get(Heimchen.Image, id) do
			nil -> resp(conn, 404, "Not found")
			image ->
				conn
				|> put_resp_content_type("application/octet-stream", nil)
				|> put_resp_header("content-disposition", ~s[attachment; filename="#{image.original_filename}"])
				|> send_file(200, Heimchen.Image.delayed_dir(image) <> "/" <>
					%{"1" => "thumb.jpg",
        		"2" => "medium.jpg",
        		"3" => "large.jpg",
        		"4" => Heimchen.Image.orig_name(image)}[size]) 
		end
	end
	
	def create(conn, %{"upload" => upload_params}, user) do
		images = Heimchen.Image.create(upload_params, user)
		cond do
			upload_params["item_id"] && String.length(upload_params["item_id"])>0  ->
				conn
				|> put_flash(:success, "#{length(images)} Bild(er) wurde hochgeladen")
				|> redirect(to: item_path(conn, :show, upload_params["item_id"]))
		  upload_params["person_id"] && String.length(upload_params["person_id"])>0 ->
				conn
				|> put_flash(:success, "#{length(images)} Bild(er) wurde hochgeladen")
				|> redirect(to: person_path(conn, :show, upload_params["person_id"]))
			upload_params["place_id"] && String.length(upload_params["place_id"])>0 ->
				conn
				|> put_flash(:success, "#{length(images)} Bild(er) wurde hochgeladen")
				|> redirect(to: place_path(conn, :show, upload_params["place_id"]))
			true ->
				conn
				|> put_session(:image_clipboard,
					Map.merge(get_session(conn, :image_clipboard), Map.new(images, fn i -> {i.id, true} end)))
				|> put_flash(:success, "#{length(images)} Bild(er) wurde hochgeladen")
				|> redirect(to: image_path(conn, :index))
		end
	end

	def show(conn, %{"id" => id}, _user) do
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
		changeset = Heimchen.Image.changeset(Repo.get(Heimchen.Image, id), image_params, user)
		case Repo.update(changeset) do
			{:ok, image} ->
				conn
				|> put_flash(:success, "Bild #{image.original_filename} geändert")
				|> redirect(to: image_path(conn, :show, id))
				{:error ,changeset}
				conn
				|> put_flash(:error, "Bild konnte nicht geändert werden")
				|> render("show.html", changeset: changeset, id: id)
		end
	end

	def mark(conn, %{"what" => "add", "id" => id}, _user) do
		conn
		|> put_session(:image_clipboard,
			Map.merge(get_session(conn, :image_clipboard), %{String.to_integer(id) => true}))
		|> json("ok")
	end

	def mark(conn, %{"what" => "rm", "id" => id}, _user) do
		conn
		|> put_session(:image_clipboard,
			Map.delete(get_session(conn, :image_clipboard), String.to_integer(id)))
		|> json("ok")
	end

	def marklist(conn, _, _user) do
		conn |> json(Heimchen.Imagetag.marklist())
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
					where: fragment("id = any(?)", ^ids),preload: [imagetags: [:person, [item: :itemtype]]])])
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
	
	def del_imagetag(conn, %{"id" => id}, _user) do
		it = Heimchen.Repo.get(Heimchen.Imagetag,id)
		Heimchen.Repo.delete(it)
		cond do 
			it.person_id -> conn|> redirect(to: person_path(conn, :show, it.person_id))
			it.item_id   -> conn|> redirect(to: item_path(conn, :show, it.item_id))
			# FIXME place
		end
	end 

	def edit_imagetag(conn, %{"id" => id}, user) do
		{w,_} = Heimchen.Image.resolution(2)
		case Repo.get(Heimchen.Imagetag, id) do
			nil -> resp(conn, 404, "Not found")
			it ->     it = Repo.preload(it, [:image, :person, [item: :itemtype]])
			          render(conn, "edit_imagetag.html",
                  [id: it.id, name: Heimchen.Imagetag.name(it),
									 w: w, imagetag: it ])
		end
	end

	def update_imagetag(conn, %{"id" => id, "imagetag" => imagetag_params}, user) do
		changeset = Heimchen.Imagetag.changeset(Repo.get(Heimchen.Imagetag, id), imagetag_params, user)
		case Repo.update(changeset) do
			{:ok, imagetag} ->
				cond do
					imagetag.person_id ->
						conn
						|> put_flash(:success, "Markierung gespeichert")
						|> redirect(to: person_path(conn, :show, imagetag.person_id))
					imagetag.item_id ->
						conn
						|> put_flash(:success, "Markierung gespeichert")
						|> redirect(to: item_path(conn, :show, imagetag.item_id))
					imagetag.place_id ->
						conn
						|> put_flash(:success, "Markierung gespeichert")
						|> redirect(to: place_path(conn, :show, imagetag.place_id))
					true -> # FIXME place
						conn
						|> put_flash(:error, "Markierung nur für Personen, Sammlungsstücke und Orte implementiert")
						|> redirect(to: person_path(conn, :index))
				end
			{:error, what} ->
				conn
				|> put_flash(:error, "Markierung konnte nicht gespeichert werden: " <> what)
				|> redirect(to: person_path(conn, :index))
		end
	end

	
end
