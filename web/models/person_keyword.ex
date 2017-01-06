defmodule Heimchen.PersonKeyword do
	use Heimchen.Web, :model
	alias Heimchen.Person
	alias Heimchen.Repo
	alias Heimchen.Keyword


	schema "people_keywords" do
		belongs_to :person, Heimchen.Person
		belongs_to :keyword, Heimchen.Keyword
		belongs_to :user, Heimchen.User

		timestamps()
	end

	def changeset(model, params, user) do
		model
		|> cast(params, ~w(keyword_id person_id))
		|> assoc_constraint(:person, message: "Person existiert nicht")
		|> assoc_constraint(:keyword, message: "Stichwort existiert nicht")
 		|> unique_constraint(:dummy, name: :people_keywords_person_id_keyword_id_index,
			message: "Diese Person hat bereits dieses Stichwort")

		|> put_change(:user_id,  user.id)
	end

	
end
