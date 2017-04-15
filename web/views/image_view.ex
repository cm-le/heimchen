defmodule Heimchen.ImageView do
  use Heimchen.Web, :view
		
	def csrf_token(conn) do
    Plug.Conn.get_session(conn, :csrf_token)
  end

	def imagetag_backlink(conn,it) do
		cond do
			it.person_id -> person_path(conn, :show, it.person_id)
			it.place_id  -> place_path(conn, :show, it.place_id)
			it.item_id  ->  item_path(conn, :show, it.item_id)
			true -> ""
		end
	end
end
