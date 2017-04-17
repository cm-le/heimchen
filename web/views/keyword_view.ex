defmodule Heimchen.KeywordView do
	use Heimchen.Web, :view

	def keyword_delete_link(conn, what, id, kid) do
		content_tag(:a, href:
			case what do
				"item"   -> item_path(conn, :delete_keyword, id, kid)
				"person" -> person_path(conn, :delete_keyword, id, kid)
				"place"  -> place_path(conn, :delete_keyword, id, kid)
			end) do
			content_tag :i, class: "fa fa-remove" do end
		end
	end
end
