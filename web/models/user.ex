defmodule Heimchen.User do
	use Heimchen.Web, :model

	schema "users" do
		field :firstname, :string
		field :lastname, :string
		field :academic, :string
		field :gender, :string
		field :avatar, :binary
		field :username, :string
		field :admin, :boolean
		field :email, :string
		field :comment, :string
		field :active, :boolean
		field :password, :string, virtual: true
		field :password_hash, :string

		timestamps
	end

	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ~w(firstname lastname gender username email), ~w(academic active))
		|> unique_constraint(:username, message: "Benutzername bereits vergeben")
	end

	
	def put_pass_hash(changeset) do
		case changeset do
			%Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
				put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
			_ -> changeset
		end
	end
	
	def password_changeset(changeset, params) do
		changeset
		|> cast(params, ~w(password), [])
		|> validate_length(:password, min: 6, message: "Das Passwort muß mindestens 6 Buchstaben lang sein")
		|> put_pass_hash()
	end
	
	def create_changeset(model, params) do
		model
		|> changeset(params)
		|> put_change(:active, true)
		|> password_changeset(params)
	end
	
end
