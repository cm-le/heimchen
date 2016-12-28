defmodule Heimchen.SessionController do
	use Heimchen.Web, :controller
	alias Heimchen.Auth
	
	def new(conn, _) do
		render conn, "new.html"
	end

	def create(conn, %{"session" => %{"username" => user, "password" => pass}}) do
		case Auth.login_by_username_and_pass(conn, user, pass) do
			{:ok, conn} ->
				conn
				|> redirect(to: item_path(conn, :index))
			{:error, conn} ->
				conn
				|> put_flash(:error, "Falscher Benutzername / Passwort")
				|> render("new.html")
		end
	end


	def delete(conn, _) do
		conn
		|> Auth.logout()
		|> put_flash(:success, "Sie sind jetzt ausgeloggt")
		|> redirect(to: session_path(conn, :new))
	end
	
end
