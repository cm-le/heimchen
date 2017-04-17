defmodule Heimchen.Person do
	use Heimchen.Web, :model
	alias Heimchen.Person
	alias Heimchen.Repo
	
	schema "people" do
		field :firstname, :string
		field :lastname,  :string
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
	
	def changeset(model, params, user) do
		model
		|> cast(params, ~w(lastname firstname born_on born_precision died_on died_precision gender comment))
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
	
	
end
