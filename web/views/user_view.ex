defmodule Heimchen.UserView do
	use Heimchen.Web, :view

	alias Heimchen.User

	def name(%User{firstname: firstname, academic: academic, lastname: lastname}) do
		[academic, firstname, lastname]
		|> Enum.filter(&(&1 && String.length(&1)>0))
		|> Enum.join(" ")
	end

	
end
