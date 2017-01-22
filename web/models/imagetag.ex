defmodule Heimchen.Imagetag do
	use Heimchen.Web, :model
	
	schema "imagetags" do
		belongs_to :image, Heimchen.Image
		belongs_to :person, Heimchen.Person

		belongs_to :user_id, Heimchen.User
		timestamps
	end
	
	def changeset(model, params, user) do
		model
		|> cast(params, ~w(lastname firstname born_on born_precision died_on died_precision comment))
		|> put_change(:user_id,  user.id)
		|> validate_required([:lastname], message: "Darf nicht leer sein")
	end

	
end
