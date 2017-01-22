defmodule Heimchen.ImageController do
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
	
	# add user as an additional parameter to every action
	def action(conn, _) do
		apply(__MODULE__, action_name(conn),
			[conn, conn.params, conn.assigns.current_user])
	end

	############
	
	def index(conn, _params, _user) do
		render(conn, "index.html", [images: Heimchen.Image.recently_uploaded()])
	end

	def new(conn, _params, _user) do
		render(conn, "new.html", [])
	end

	def thumb(conn, %{"id" => id}, _user) do
		case Repo.get(Heimchen.Image, id) do
			nil -> resp(conn, 404, "Not found")
			image -> send_file(conn, 200, Heimchen.Image.dir(image) <> "/thumb.jpg")
		end
	end
	
	def create(conn, %{"upload" => upload_params}, user) do
		case Heimchen.Image.create(upload_params, user) do
			{:ok, images} ->
				conn
				|> put_flash(:success, "Bild wurde hochgeladen")
				|> redirect(to: image_path(conn, :index))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Bild konnte niche eingelesen werden")
				|> redirect(to: image_path(conn, :new))
		end
	end
	
end
