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

		has_many   :people_keywords, Heimchen.PersonKeyword
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


	def  with_keywords(q) do
		q |>
			select([p], {p,
										(fragment("(select string_agg( k.category || ':' || k.name, ', ') from people_keywords pk, keywords k where pk.keyword_id=k.id and pk.person_id=p0.id)"))})
		|> order_by([:lastname, :firstname])
		|> limit(100)
	end

	def recently_updated() do
		(from p in Heimchen.Person, preload: [imagetags: :image],
			order_by: [desc: p.updated_at], limit: 100)
		|> with_keywords()
		|> Repo.all
	end

	
	def search(s) do
		case String.split(s, ~r{\s*,\s*}, parts: 2) do
			[<<"#"::utf8, keyword::binary>> | _]  ->
				from p in Person, join: pk in assoc(p, :people_keywords),
					join: k in assoc(pk, :keyword), where: fragment("length(?) > 0 and ? ~* ?", ^keyword, k.name, ^keyword),
				  distinct: p.id
			[lastname] ->
				from p in Person, where: fragment("? ~* ?", p.lastname, ^lastname)
			[lastname, firstname] ->
					from p in Person, where: fragment("? ~* ?", p.lastname, ^lastname),
					where: fragment("? ~* ?", p.firstname, ^firstname)
			_ -> from p in Person, where: p.id == -1
		end
		|> with_keywords() |> Repo.all
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
