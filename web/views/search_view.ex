defmodule Heimchen.SearchView do
  use Heimchen.Web, :view


	def catname(what) do
		names = %{"person" => "Person",
							"keyword" => "Stichwort",
							"image" => "Datei",
							"item" => "Sammlung",
							"place" => "Ort" }
		names[what]
	end 

	def resultlink(conn, what, name, id) do
		case what do
			"person"  -> link(name, to: person_path(conn, :show, id))
			"item"    -> link(name, to: item_path(conn, :show, id))
			"image"   -> link(name, to: image_path(conn, :show, id))
			"keyword" -> link(name, to: keyword_path(conn, :show, id))
			"place"   -> link(name, to: place_path(conn, :show, id))
		end
	end
	
end
