require IEx
defmodule Heimchen.Imagetag do
	use Heimchen.Web, :model
	
	schema "imagetags" do
		belongs_to :image, Heimchen.Image
		belongs_to :person, Heimchen.Person

		field :marks, :map
		field :comment, :string
		belongs_to :user, Heimchen.User
		timestamps
	end

	def marklist() do
		(from p in Heimchen.Person, 
			select: {p.id, p.firstname, p.lastname}, order_by: [p.lastname, p.firstname])
		|> Heimchen.Repo.all()
		|> Enum.map(fn({_id, firstname, lastname}) -> "Person: #{lastname}, #{firstname}" end)
	end

	def find_mark(mark) do
		m = Regex.named_captures(~r/Person: (?<lastname>[^,]+), (?<firstname>.+)/, mark)
		person = Heimchen.Repo.get_by(Heimchen.Person, lastname: m["lastname"], firstname: m["firstname"])
		%{:person_id => person.id}
	end

	def add_person_mark(person_id, image_id, user) do
		if Heimchen.Repo.get_by(Heimchen.Imagetag, person_id: person_id, image_id: image_id) do 0 else
			Heimchen.Repo.insert(%Heimchen.Imagetag{image_id: image_id, person_id: person_id, user_id: user.id})
			1
		end
	end
	
	def create_from_marklist(imageids, mark, user) do
		markmap = find_mark(mark)
		Enum.map(imageids, fn(image_id) -> # FIXME differenciate by markmap entry
			add_person_mark(markmap.person_id, image_id, user)
		end) |> Enum.sum()
	end

	def name(it) do
		if it.person_id do
			it = Heimchen.Repo.preload(it, :person)
			Heimchen.Person.name(it.person)
		else
			""
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
		|> cast(params, ~w(comment))
	end


	
end
