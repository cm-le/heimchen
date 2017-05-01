require IEx
defmodule Heimchen.Imagetag do
	use Heimchen.Web, :model
	alias Heimchen.Repo
	alias Heimchen.Imagetag
	
	schema "imagetags" do
		belongs_to :image, Heimchen.Image
		belongs_to :person, Heimchen.Person
		belongs_to :item, Heimchen.Item
		belongs_to :place, Heimchen.Place
		
		field :marks, :map
		field :comment, :string
		field :is_primary, :boolean
		belongs_to :user, Heimchen.User
		timestamps
	end

	def marklist() do
		(Repo.all(from p in Heimchen.Person, order_by: [p.lastname, p.firstname])
			|> Enum.map(fn(p) -> "Person: #{p.lastname}, #{p.firstname} [#{p.id}]" end)) ++
		(Repo.all(from p in Heimchen.Place, order_by: [p.city, p.address])
			|> Enum.map(fn(p) -> "Ort: #{Heimchen.Place.longname(p)} [#{p.id}]" end)) ++
		(Repo.all(from i in Heimchen.Item, preload: [:itemtype], order_by: [:itemtype_id, :name])
			|> Enum.map(fn(i) -> "#{i.itemtype.name}: #{i.name} [#{i.id}]" end))
	end

	def find_mark(mark) do
		case Regex.run(~r{([^:]+).*\[(\d+)\]$}, mark) do
			[_, "Person", id] -> {:person, String.to_integer(id)}
			[_, "Ort", id] -> {:place, String.to_integer(id)}
			[_, _, id] -> {:item, String.to_integer(id)}
			_ -> {:error}
		end
	end

	def add_person_mark(person_id, image_id, user) do
		if Repo.get_by(Imagetag, person_id: person_id, image_id: image_id) do 0 else
			Repo.insert(%Imagetag{image_id: image_id, person_id: person_id, user_id: user.id})
			1
		end
	end

	def add_place_mark(place_id, image_id, user) do
		if Repo.get_by(Imagetag, place_id: place_id, image_id: image_id) do 0 else
			Repo.insert(%Imagetag{image_id: image_id, place_id: place_id, user_id: user.id})
			1
		end
	end


	def add_item_mark(item_id, image_id, user) do
		if Repo.get_by(Imagetag, item_id: item_id, image_id: image_id) do 0 else
			Repo.insert(%Imagetag{image_id: image_id, item_id: item_id, user_id: user.id})
			1
		end
	end

	
	def create_from_marklist(imageids, mark, user) do
		mark = find_mark(mark)
		Enum.map(imageids, fn(image_id) -> # FIXME differenciate by markmap entry
			case mark do
				{:person, id} -> add_person_mark(id, image_id, user)
				{:item, id} ->   add_item_mark(id, image_id, user)
				{:place, id} ->  add_place_mark(id, image_id, user)
			end
		end) |> Enum.sum()
	end

	def name(it) do
		cond do
			it.person_id -> Heimchen.Person.name(Repo.preload(it, :person).person)
			it.item_id   -> Heimchen.Item.longname(Repo.preload(it, :item).item)
			it.place_id  -> Heimchen.Place.longname(Repo.preload(it, :place).place)
			true -> ""
		end
	end
	
	def changeset(model, params, user) do
		result = changeset(model, params)
		|> put_change(:user_id,  user.id)
		if params["marks"] && is_binary(params["marks"]) && String.length(params["marks"])>0 do
			result |> put_change(:marks, Poison.decode!(params["marks"]))
		else
			result
		end
	end

	def changeset(model, params \\ :invalid) do
		model
		|> cast(params, ~w(comment is_primary))
	end
	
end
