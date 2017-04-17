defmodule Heimchen.SearchView do
  use Heimchen.Web, :view


	def catname(what) do
		names = %{"person" => "fa-male",
							"keyword" => "Stichwort",
							"image" => "fa-file",
							"item" => "fa-photo",
							"place" => "fa-globe" }
		content_tag(:i, class: "fa #{names[what]}") do end
	end 

	def resultlink(conn, what, name, id) do
		link(name, to:
			case what do
				"person"  -> person_path(conn, :show, id)
				"item"    -> item_path(conn, :show, id)
				"image"   -> image_path(conn, :show, id)
				"keyword" -> keyword_path(conn, :show, id)
				"place"   -> place_path(conn, :show, id)
			end
			)
	end
	
	def editlink(conn, what, id) do
		content_tag(:a, href:
			case what do
				"person"  -> person_path(conn, :edit, id)
				"item"    -> item_path(conn, :edit, id)
				"image"   -> image_path(conn, :edit, id)
				"keyword" -> keyword_path(conn, :edit, id)
				"place"   -> place_path(conn, :edit, id)
			end) do
			content_tag(:i, class: "fa fa-edit") do
			end
		end
	end

end
