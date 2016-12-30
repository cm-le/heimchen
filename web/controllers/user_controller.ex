defmodule Heimchen.UserController do
	use Heimchen.Web, :controller
	plug :authenticate
	plug :authenticate_admin when action in ~w(index new create)
	alias Heimchen.User

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

	defp authenticate_admin(conn, _opts) do
		if conn.assigns.current_user.admin do
			conn
		else
			conn
			|> put_flash(:error, "Sie haben keine Administrator-Rechte")
			|> redirect(to: session_path(conn, :new))
			|> halt()
		end
	end
	
	def index(conn, _params) do
		users = Repo.all from u in User, order_by: [u.lastname, u.firstname]
		render conn, "index.html", users: users
	end

	def show(conn, %{"id" => id}) do
		if !(conn.assigns.current_user.admin || ("#{conn.assigns.current_user.id}" == id)) do
			conn
			|> put_flash(:error, "Sie haben keine Admin-Rechte, Umleitung auf Ihr Profil")
			|> redirect(to: user_path(conn, :show, conn.assigns.current_user.id))
			|> halt()
		end
		user = Repo.get(User, id)
		changeset = User.changeset(user)
		render(conn, "show.html", changeset: changeset, id: id)
	end


	def new(conn, _params) do
		changeset = User.changeset(%User{})
		render(conn, "new.html", changeset: changeset)
	end


	def create(conn, %{"user" => user_params}) do
		changeset = User.create_changeset(%User{}, user_params)
		case Repo.insert(changeset) do
			{:ok, user} ->
				conn
				|> put_flash(:success, "Benutzer #{user.username} angelegt")
				|> redirect(to: user_path(conn, :index))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Benutzer konnte nicht angelegt werden")
				|> render("new.html", changeset: changeset)
		end
	end

	def update(conn, %{"id" => id, "user" => user_params}) do
		if !(conn.assigns.current_user.admin || ("#{conn.assigns.current_user.id}" == id)) do
			conn
			|> put_flash(:error, "Sie haben keine Admin-Rechte")
			|> redirect(to: session_path(conn, :new))
			|> halt()
		end

		changeset = User.changeset(Repo.get(User, id), user_params)
		case Repo.update(changeset) do
			{:ok, user} ->
				conn
				|> put_flash(:success, "Benutzer #{user.username} geändert")
				|> redirect(to: user_path(conn, :show, id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Benutzer konnte nicht geändert werden")
				|> render("show.html", changeset: changeset, id: id)
		end
	end
	
	def changepw(conn, %{"id" => id, "user" => user_params}) do
		if !(conn.assigns.current_user.admin || ("#{conn.assigns.current_user.id}" == id)) do
			conn
			|> put_flash(:error, "Sie haben keine Admin-Rechte")
			|> redirect(to: session_path(conn, :new))
			|> halt()
		end
		changeset = User.password_changeset(Repo.get(User,id), user_params)
		case Repo.update(changeset) do
			{:ok, user} ->
				conn
				|> put_flash(:success, "Passwort von Benutzer #{user.username} wurde geändert")
				|> redirect(to: user_path(conn, :show, id))
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Passwort konnte nicht geändert werden")
				|> render("show.html", changeset: changeset)
		end
	end
	
end
