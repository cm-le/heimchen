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

	def result_path(conn, what, id) do
		case what do
			"person"  -> person_path(conn, :show, id)
			"item"    -> item_path(conn, :show, id)
			"image"   -> image_path(conn, :show, id)
			"keyword" -> keyword_path(conn, :show, id)
			"place"   -> place_path(conn, :show, id)
		end
	end
	
	def editlink(conn, what, id) do
		content_tag(:a, href:
			case what do
				"person"  -> person_path(conn, :edit, id)
				"item"    -> item_path(conn, :edit, id)
				"image"   -> image_path(conn, :show, id)
				"keyword" -> keyword_path(conn, :edit, id)
				"place"   -> place_path(conn, :edit, id)
			end) do
			content_tag(:i, class: "fa fa-edit") do
			end
		end
	end

	def imagetag_backlink(conn,it) do
		cond do
			it.person_id -> person_path(conn, :show, it.person_id)
			it.place_id  -> place_path(conn, :show, it.place_id)
			it.item_id  ->  item_path(conn, :show, it.item_id)
			true -> ""
		end
	end


	def last_updated(x) do
		# believe me, I tried for 10 minutes to write this more clever....
		u = Timex.Timezone.convert(x.updated_at, "Etc/UTC")
		now = Timex.Timezone.convert(Timex.now(), "Europe/Berlin") 
		cond do
			Timex.diff(now, u, :years) > 0   -> "vor #{Timex.diff(now, u, :years)} Jahren"
			Timex.diff(now, u, :months) > 0  -> "vor #{Timex.diff(now, u, :months)} Monaten"
			Timex.diff(now, u, :weeks) > 0   -> "vor #{Timex.diff(now, u, :weeks)} Wochen"
			Timex.diff(now, u, :days) > 0    -> "vor #{Timex.diff(now, u, :days)} Tagen"
			Timex.diff(now, u, :hours) > 0   -> "vor #{Timex.diff(now, u, :hours)} Stunden"
			Timex.diff(now, u, :minutes) > 0 -> "vor #{Timex.diff(now, u, :minutes)} Minuten"
			true -> "gerade eben"
		end
	end
	
end
