defmodule Heimchen.Place do
	use Heimchen.Web, :model
	alias Heimchen.Place
	alias Heimchen.Repo


	schema "places" do
		field :city, :string
		field :address, :string
		field :comment, :string
		field :lat, :float
		field :long, :float
		many_to_many :keywords, Heimchen.Keyword, join_through: "places_keywords"
		has_many   :imagetags, Heimchen.Imagetag
		has_many   :places_items, Heimchen.PlaceItem
		has_many   :places_people, Heimchen.PlacePerson
		belongs_to :user, Heimchen.User
		timestamps
	end

	def setLatLong() do
		key = Application.get_env(:heimchen, :googleapikey)
		# HTTPotion
	end

	def touch!(place,user) do
		Repo.update(change(place, %{:user_id => user.id}), force: true)
	end
	
	def touch_id!(place_id,user) do
		Repo.update(change(Repo.get(Place, place_id), %{:user_id => user.id}), force: true)
	end

	def changeset(model, params, user) do
		model
		|> cast(params, ~w(city address comment lat long))
		|> put_change(:user_id,  user.id)
		|> validate_required([:city], message: "Darf nicht leer sein")
	end

	def recently_updated() do
		Repo.all from p in Heimchen.Place,
			preload: [:user, :keywords,
								imagetags: :image,
								places_items: [item: :itemtype],
								places_people: :person],
			order_by: [desc: p.updated_at], limit: 100
	end

	def nearby(place) do
		# make this all use spacial datatypes ind indices in the far future...
		Repo.all from p in Heimchen.Place,
			order_by:  fragment("sqrt((p.lat - ?)^2 + (p.long - ?)^2)", ^place.lat, ^place.long),
			limit: 100
	end
	
end
