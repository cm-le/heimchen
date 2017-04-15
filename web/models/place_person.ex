defmodule Heimchen.PlacePerson do
	use Heimchen.Web, :model

	schema "places_people" do
		field      :start_on, Ecto.Date
		field      :start_precision, :integer
		field      :comment, :string
		belongs_to :place, Heimchen.Place
		belongs_to :person, Heimchen.Person
		belongs_to :user, Heimchen.User

		timestamps()
	end

	def changeset(model, params, user) do
		model
		|> cast(params, ~w(person_id place_id comment start_on start_precision))
		|> assoc_constraint(:place, message: "Ort existiert nicht")
		|> assoc_constraint(:person, message: "Person existiert nicht")
		|> put_change(:user_id,  user.id)
	end
	
end
