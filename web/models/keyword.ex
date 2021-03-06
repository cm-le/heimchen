require IEx
defmodule Heimchen.Keyword do
	use Heimchen.Web, :model
	alias Heimchen.Keyword
	alias Heimchen.Repo
	
	schema "keywords" do
		field :name, :string
		field :comment, :string
		field :category, :string

		field :for_person, :boolean
		field :for_place, :boolean

		field :for_photo_item, :boolean
		field :for_film_item,  :boolean
		field :for_event_item, :boolean
		field :for_thing_item, :boolean
		
		belongs_to :user, Heimchen.User

		many_to_many :people, Heimchen.Person, join_through: "people_keywords"
		many_to_many :items,  Heimchen.Item,   join_through: "item_keywords"
		many_to_many :places, Heimchen.Place,   join_through: "places_keywords"

		timestamps
	end
	
	def changeset(model, params, user) do
		model
		|> cast(params, ~w(name category comment for_person for_place
					for_film_item for_event_item for_thing_item for_photo_item))
		|> put_change(:user_id,  user.id)
		|> put_change(:category,
		   if params != :invalid do
				 if params["new_category"] != "" do
					 params["new_category"]
				 else params["category"]
				 end
			 else ""
			 end)
		|> validate_required([:name, :category], message: "Darf nicht leer sein")
		|> unique_constraint(:name, name: :keywords_category_name_index,
			message: "Dieses Stichwort existiert bereits in dieser Kategorie")
	end

	def id_by_cat_name("") do nil end
	def id_by_cat_name(cn) do
		[c,n] = String.split(cn, ~r{: }, parts: 2)
		case Repo.get_by(Keyword, category: c, name: n) do
			nil -> nil
			keyword -> keyword.id
		end
	end
	
	
	def categories() do
		Repo.all from(k in Keyword, distinct: true, select: k.category, order_by: k.category)
	end
	
end
