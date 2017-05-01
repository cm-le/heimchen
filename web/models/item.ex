require IEx
defmodule Heimchen.Item do
	use Heimchen.Web, :model
	alias Heimchen.Item
	alias Heimchen.Repo
	
	schema "items" do
		field :name, :string
		field :comment, :string
		field :date_on, Ecto.Date
		field :date_precision, :integer
		belongs_to :received_by, Heimchen.Person
		belongs_to :room, Heimchen.Room
		field :received_comment, :string
		field :inventory, :string
		field :filenr, :string
		field :filecomment, :string

		belongs_to :itemtype, Heimchen.Itemtype
		belongs_to :user, Heimchen.User
		many_to_many :keywords, Heimchen.Keyword, join_through: "item_keywords"
		has_many   :places_items, Heimchen.PlaceItem
		has_many   :imagetags, Heimchen.Imagetag
		timestamps
	end


	def touch!(item,user) do
		Repo.update(change(item, %{:user_id => user.id}), force: true)
	end
	
	def touch_id!(item_id,user) do
		Repo.update(change(Repo.get(Item, item_id), %{:user_id => user.id}), force: true)
	end

	def skiplist(item) do
		{:ok, %{rows: results, num_rows: _}} =
			Ecto.Adapters.SQL.query(Heimchen.Repo,
				"select (select min(id) from items), " <>
					"(select max(id) from items), " <>
					" (select max(id) from items where id<$1)," <>
					" (select min(id) from items where id>$1)", [item.id])
		[min, max, prev, next] = List.first results
		%{min: min, max: max, prev: prev, next: next}
	end
	
	def changeset(model, params, user) do
		model
		|> cast(params, ~w(name comment date_on date_precision received_by_id
					received_comment inventory filenr filecomment itemtype_id))
		|> put_change(:user_id,  user.id)
		|> validate_required([:name], message: "Darf nicht leer sein")
	end

	def to_result(item) do
		%{what: "item",
			id: item.id,
			name: item.name,
			comment: item.comment,
			keywords: item.keywords,
			image_id: case item.imagetags do
									[] -> nil
									[it |_] -> it.image_id
								end
			}
	end
	
	def recently_updated() do
		(Repo.all from i in Heimchen.Item,
			preload: [:itemtype, :keywords, :imagetags],
			order_by: [desc: i.updated_at], limit: 100)
		|> Enum.map(fn x -> to_result(x) end)
	end
	
	def search(s) do
		Repo.all from i in Heimchen.Item,
			where: fragment("? ~* ?", i.name, ^s),
			preload: [:itemtype, :keywords],
			order_by: [desc: i.updated_at], limit: 100
	end

	def longname(item) do
		item = Repo.preload(item, :itemtype)
		"#{item.itemtype.name}: #{item.name}"
	end
	
end
