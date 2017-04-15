defmodule Heimchen.PlaceKeyword do
	use Heimchen.Web, :model

	schema "places_keywords" do
		belongs_to :place, Heimchen.Place
		belongs_to :keyword, Heimchen.Keyword
		belongs_to :user, Heimchen.User

		timestamps()
	end

	def changeset(model, params, user) do
		model
		|> cast(params, ~w(keyword_id place_id))
		|> assoc_constraint(:place, message: "Ort existiert nicht")
		|> assoc_constraint(:keyword, message: "Stichwort existiert nicht")
 		|> unique_constraint(:dummy, name: :people_keywords_person_id_keyword_id_index,
			message: "Dieser Ort hat bereits dieses Stichwort")
		|> put_change(:user_id,  user.id)
	end
	
end
