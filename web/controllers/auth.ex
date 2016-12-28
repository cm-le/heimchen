defmodule Heimchen.Auth do
	import Plug.Conn
	alias Heimchen.Repo

	def init(_) do
	end
	
	def call(conn, repo) do
		user_id = get_session(conn, :user_id)
		user    = user_id && Repo.get(Heimchen.User, user_id)
		assign(conn, :current_user, user)
	end

	
	def login(conn, user) do
		conn
		|> assign(:current_user, user)
		|> put_session(:user_id, user.id)
		|> configure_session(renew: true)
	end

	def login_by_username_and_pass(conn, username, given_pass) do
		user = Repo.get_by(Heimchen.User, username: username)

		cond do
			user && user.active && Comeonin.Bcrypt.checkpw(given_pass, user.password_hash) ->
				{:ok, login(conn, user)}
			true ->
				{:error, conn}
		end
	end


	def logout(conn) do
		configure_session(conn, drop: true)
	end
end
