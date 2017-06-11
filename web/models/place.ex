defmodule Heimchen.Place do
	use Heimchen.Web, :model
	alias Heimchen.Place
	alias Heimchen.Repo


	schema "places" do
		field :city, :string
		field :address, :string
		field :building, :string
		field :housenr, :string
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
		HTTPoison.start
		case HTTPoison.get("https://maps.googleapis.com/maps/api/geocode/json?address=" <>
					URI.encode("#{place.city},+#{place.address}+#{place.housenr}") <>
					"&key=#{key}") do
			{:ok, %HTTPoison.Response{body: body}} ->
				case Poison.decode!(body) do
					%{"results" => [%{"geometry" => %{"location" => %{"lat" => latitude, "lng" => longitude}}} |_]}
						-> Repo.update(change(place, %{:lat => latitude, :long => longitude}))
					_ -> {:error}
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
		|> cast(params, ~w(city address comment building housenr lat long))
		|> put_change(:user_id,  user.id)
		|> validate_required([:city], message: "Darf nicht leer sein")
	end

	def to_result(place) do
		%{what: "place",
			id: place.id,
			name: longname(place),
			comment: place.comment,
			keywords: place.keywords,
			image_id: case place.imagetags do
									[] -> nil
									[it |_] -> it.image_id
								end
			}
	end

	
	def recently_updated() do
		(Repo.all from p in Heimchen.Place,
			preload: [:user, :keywords,
								:imagetags,
								places_items: [item: :itemtype],
								places_people: :person],
			order_by: [desc: p.updated_at], limit: 100)
		|> Enum.map(fn x -> to_result(x) end)
	end

	def nearby(place) do
		# make this all use spacial datatypes ind indices in the far future...
		(Repo.all from p in Heimchen.Place,
			preload: [:user, :keywords,
								imagetags: :image,
								places_items: [item: :itemtype],
								places_people: :person],# around 10km(?)
		where: fragment("? != ? and sqrt((? - ?)^2 + (? - ?)^2)< 0.1",
			p.id, ^place.id, p.lat, ^place.lat, p.long, ^place.long),
			order_by:  fragment("sqrt((? - ?)^2 + (? - ?)^2)",
				p.lat, ^place.lat, p.long, ^place.long),
			limit: 10)
		|> Enum.map(fn x -> to_result(x) end)
	end

	
	def skiplist(place) do
		{:ok, %{rows: results, num_rows: _}} =
			Ecto.Adapters.SQL.query(Heimchen.Repo,
				"select (select min(id) from places), " <>
					"(select max(id) from places), " <>
					" (select max(id) from places where id<$1)," <>
					" (select min(id) from places where id>$1)", [place.id])
		[min, max, prev, next] = List.first results
		%{min: min, max: max, prev: prev, next: next}
	end

	
	def longname(place) do
		"#{place.city}: #{place.address} #{place.housenr}" <>
		(if place.building && String.length(place.building)>0 do " (#{place.building})" else "" end)
	end

	def knownplaces() do
		Repo.all from p in Heimchen.Place,
			where: not(is_nil(p.lat) or is_nil(p.long))
	end

	def unknownplaces() do
		(Repo.all from p in Heimchen.Place,
			where: is_nil(p.lat) or is_nil(p.long),
			preload: [:user, :keywords,
								:imagetags,
								places_items: [item: :itemtype],
								places_people: :person],
			order_by: [desc: p.address])
		|> Enum.map(fn x -> to_result(x) end)
	end

	
	def for_select() do
		(Repo.all from p in Heimchen.Place,
			order_by: [fragment("updated_at = (select max(updated_at) from places)"),
								 p.city,
								 p.address,
								 p.housenr])
		|> Enum.map(fn (p) -> {longname(p), p.id} end)
	end
	
end
