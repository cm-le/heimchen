defmodule Heimchen.PlaceItem do
	use Heimchen.Web, :model

	schema "places_items" do
		field      :start_on, Ecto.Date
		field      :start_precision, :integer
		field      :comment, :string
		belongs_to :place, Heimchen.Place
		belongs_to :item, Heimchen.Item
		belongs_to :user, Heimchen.User
		
		timestamps()
	end

	def changeset(model, params, user) do
		model
		|> cast(params, ~w(item_id place_id comment start_on))
		|> assoc_constraint(:place, message: "Ort existiert nicht")
		|> assoc_constraint(:item, message: "Nicht in der Sammlung gefunden")
		|> put_change(:user_id,  user.id)
	end
	
end
