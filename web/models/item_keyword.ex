defmodule Heimchen.ItemKeyword do
	use Heimchen.Web, :model
	alias Heimchen.Item
	
	schema "item_keywords" do
		belongs_to :item, Heimchen.Item
		belongs_to :keyword, Heimchen.Keyword
		belongs_to :user, Heimchen.User

		timestamps()
	end

	def changeset(model, params, user) do
		model
		|> cast(params, ~w(keyword_id item_id))
		|> assoc_constraint(:item, message: "Person existiert nicht")
		|> assoc_constraint(:keyword, message: "Stichwort existiert nicht")
 		|> unique_constraint(:dummy, name: :people_keywords_person_id_keyword_id_index,
			message: "Diese Person hat bereits dieses Stichwort")

		|> put_change(:user_id,  user.id)
	end

	
end
