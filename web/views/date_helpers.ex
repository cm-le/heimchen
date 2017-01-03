defmodule Heimchen.DateHelpers do
  use Phoenix.HTML

	def heimchen_date_select(form, field, opts \\ []) do
		builder = fn b ->
			[content_tag(:div, b.(:day, opts), class: "col-sm-1"),
			 content_tag(:div, b.(:month, opts ++ [{:options, [{"Januar",1}, {"Februar",2},
																												 {"März",3}, {"April", 4}, {"Mai", 5},
																												 {"Juni", 6}, {"Juli", 7}, {"August", 8},
																												 {"September", 9}, {"Oktober", 10},
																												 {"November", 11}, {"Dezember", 12}]}]),
				 class: "col-sm-2"),
			 content_tag(:div, b.(:year, opts ++ [{:options, 2020..1500}] ), class: "col-sm-2")] 
		end
		
		datetime_select(form, field, [builder: builder] ++ opts)
	end

	def heimchen_date_precision(form, field, opts \\ []) do
		select(form, field, ["--keine Angabe--": "0", "genau": "1", "Jahr/Monat": "2",
												 "nur Jahr": "3", "ungefähr": "4"], opts)
	end

	def heimchen_show_date(0, _) do
		tag :i do "keine Angabe" end
	end
	def heimchen_show_date(precision, _) do
		tag :i do precision end
	end

end
