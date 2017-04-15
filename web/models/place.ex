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

	def setLatLong(place) do
		key = Application.get_env(:heimchen, :googleapikey)
		case HTTPotion.get("https://maps.googleapis.com/maps/api/geocode/json?address=" <>
					URI.encode("#{place.city},+#{place.address}") <>
					"&key=#{key}") do
			%HTTPotion.Response{body: body} ->
				case Poison.decode!(body) do
					%{} -> "hallo"
				end
			_ -> {:error}
		end
		
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
								:imagetags,
								places_items: [item: :itemtype],
								places_people: :person],
			order_by: [desc: p.updated_at], limit: 100
	end

	def nearby(place) do
		# make this all use spacial datatypes ind indices in the far future...
		Repo.all from p in Heimchen.Place,
			preload: [:user, :keywords,
								imagetags: :image,
								places_items: [item: :itemtype],
								places_people: :person],# around 50km
		where: fragment("? != ? and sqrt((? - ?)^2 + (? - ?)^2)< 0.5",
			p.id, ^place.id, p.lat, ^place.lat, p.long, ^place.long),
			order_by:  fragment("sqrt((? - ?)^2 + (? - ?)^2)",
				p.lat, ^place.lat, p.long, ^place.long),
			limit: 100
	end

	def longname(place) do
		"#{place.city} #{place.address}"
	end

	def for_select() do
		(Repo.all from p in Heimchen.Place,
			order_by: [fragment("updated_at = (select max(updated_at) from places)"),
								 p.city,
								 p.address],
			select: [p.city, p.address, p.id])
		|> Enum.map(fn ([city, address, id]) -> {Enum.join([city, address], " "), id} end)
	end
	
end
