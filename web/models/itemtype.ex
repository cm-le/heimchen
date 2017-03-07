defmodule Heimchen.Itemtype do
	use Heimchen.Web, :model

	schema "itemtypes" do
		field :name, :string
		field :sid, :string
		field :has_room, :boolean
	end

end
