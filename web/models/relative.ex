defmodule Heimchen.Relative do
	use Heimchen.Web, :model

	schema "relatives" do
		field :relname, :string
		field :relname_back, :string
		belongs_to :person1, Heimchen.Person
		belongs_to :person2, Heimchen.Person
		belongs_to :user, Heimchen.User

		timestamps()
	end

	def changeset(model, params, user) do
		model
		|> cast(params, ~w(person1_id person2_id relname relname_back))
		|> assoc_constraint(:person1, message: "Erste Person existiert nicht")
		|> assoc_constraint(:person2, message: "Zweite Person existiert nicht")
		|> put_change(:user_id,  user.id)
	end
	
end
