defmodule Heimchen.Person do
	use Heimchen.Web, :model
	alias Heimchen.Person
	alias Heimchen.Repo
	
	schema "people" do
		field :firstname, :string
		field :lastname,  :string
		field :maidenname, :string
		field :gender,    :string
		field :born_on, Ecto.Date
		field :born_precision, :integer
		field :died_on, Ecto.Date
		field :died_precision, :integer
		field :comment, :string

		many_to_many :keywords, Heimchen.Keyword, join_through: "people_keywords"
		has_many   :places_people, Heimchen.PlacePerson
		has_many   :imagetags, Heimchen.Imagetag
		has_many   :items, Heimchen.Item, foreign_key: :received_by_id
		
		belongs_to :user, Heimchen.User
		timestamps
	end

	def skiplist(person) do
		{:ok, %{rows: results, num_rows: _}} =
			Ecto.Adapters.SQL.query(Heimchen.Repo,
				"select (select min(id) from people), " <>
					"(select max(id) from people), " <>
					" (select max(id) from people where id<$1)," <>
					" (select min(id) from people where id>$1)", [person.id])
		[min, max, prev, next] = List.first results
		%{min: min, max: max, prev: prev, next: next}
	end

	
	def changeset(model, params, user) do
		model
		|> cast(params, ~w(lastname firstname maidenname born_on born_precision died_on died_precision gender comment))
		|> put_change(:user_id,  user.id)
		|> validate_required([:lastname], message: "Darf nicht leer sein")
	end

	

	def to_result(person) do
		%{what: "person",
			id: person.id,
			name: Person.name(person),
			comment: person.comment,
			keywords: person.keywords,
			image_id: case person.imagetags do
									[] -> nil
									[it |_] -> it.image_id
								end
			}
	end

	def recently_updated() do
		(Repo.all from p in Heimchen.Person, preload: [:imagetags, :keywords],
			order_by: [desc: p.updated_at], limit: 100)
		|> Enum.map(fn x -> to_result(x) end)
	end

	
	def name(p) do
		"#{p.firstname} #{p.lastname}"
	end

	def eman(p) do
		"#{p.lastname}, #{p.firstname}"
	end

	
	def keywords(person) do
		Repo.all from pk in Heimchen.PersonKeyword,
			where: pk.person_id==^person.id,
			join: k in assoc(pk, :keyword),
			select: %{id: pk.id, name: k.name, category: k.category, keyword_id: k.id},
			order_by: [k.category, k.name]
	end


	def relatives(person) do
		(Repo.all from r in Heimchen.Relative,
		  where: r.person1_id == ^person.id or r.person2_id == ^person.id)
		|> Repo.preload([:person1, :person2])
	end


	def for_select() do
		(Repo.all from p in Heimchen.Person,
			order_by: [fragment("updated_at = (select max(updated_at) from places)"),
								 p.lastname,
								 p.firstname])
		|> Enum.map(fn (p) -> {"#{p.lastname}, #{p.firstname}", p.id} end)
	end

	
end
