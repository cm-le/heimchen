defmodule Heimchen.Room do
	use Heimchen.Web, :model

	schema "rooms" do
		field :name, :string
	end

	# currently managed via direct database access
	
end
