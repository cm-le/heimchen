defmodule Heimchen.DateHelpers do
  use Phoenix.HTML

	@monthnames [{"Januar",1}, {"Februar",2},
		 {"März",3}, {"April", 4}, {"Mai", 5},
		 {"Juni", 6}, {"Juli", 7}, {"August", 8},
		 {"September", 9}, {"Oktober", 10},
		 {"November", 11}, {"Dezember", 12}]
	
	def heimchen_date_select(form, field, opts \\ []) do
		builder = fn b ->
			[content_tag(:div, b.(:day, opts), class: "col-sm-2"),
			 content_tag(:div, b.(:month, opts ++ [{:options, @monthnames}]),
				 class: "col-sm-2"),
			 content_tag(:div, b.(:year, opts ++ [{:options, 2020..1500}] ), class: "col-sm-2")] 
		end
		
		date_select(form, field, [builder: builder] ++ opts)
	end

	def heimchen_date_precision(form, field, opts \\ []) do
		select(form, field, ["--keine Angabe--": "0", "genau": "1", "Jahr/Monat": "2",
												 "nur Jahr": "3", "ungefähr": "4", "nach": "5", "vor": "6"], opts)
	end

	def heimchen_show_date(0,_) do
		content_tag :span do "---" end
	end
	
	def heimchen_show_date(precision, %{day: d, month: m, year: y}) do
		content_tag :span do
			case precision do
				1 ->  "#{d}.#{m}.#{y}" 
        2 -> "#{m}/#{y}" 
        3 ->  "#{y}" 
        4 ->  "ca. #{y}"
				5 ->  "nach #{y}"
			  6 ->  "vor #{y}"
				_ -> "unbekannt"			
			end
		end
	end

	def show_timestamp(t) do
		{{y,m,d},{h,min,_}} = NaiveDateTime.to_erl(t)
		"#{d}.#{m}.#{y} #{h}:#{min}"
	end
	
end
