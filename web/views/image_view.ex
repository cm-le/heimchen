defmodule Heimchen.ImageView do
  use Heimchen.Web, :view
		
	def csrf_token(conn) do
    Plug.Conn.get_session(conn, :csrf_token)
  end

	def imagetag_backlink(conn,it) do
		if it.person_id do
			person_path(conn, :show, it.person_id)
		else
			""
		end
	end
end
