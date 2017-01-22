require IEx
defmodule Heimchen.Image do
	use Heimchen.Web, :model
	alias Heimchen.Person
	alias Heimchen.Repo

	@basepath  Application.app_dir(:heimchen, "priv/uploads")
	
	schema "images" do
		field :original_filename, :string
		field :exif, :map
		field :ratio_x_by_y, :float
		field :pathname_orig, :string
		field :pathname_thumb, :string
		field :pathname_medium, :string
		field :pathname_large, :string
		field :comment, :string
		field :shot_at, Ecto.DateTime
		field :shot_by, :string

		belongs_to :user, Heimchen.User
		has_many :imagetags, Heimchen.Imagetag
		timestamps
	end


	def create_one(file_path,original_filename, comment, user) do
		# IEx.pry
		Repo.insert(changeset(%Heimchen.Image{},
					%{:comment => comment,
						:original_filename => original_filename}, user))
	end
	
	def create(%{"file" => file, "comment" => comment}, user) do
		extension = Path.extname(file.filename)
		if extension == "zip" do
			## FIXME
		else
			create_one(file.path, file.filename, comment, user)
		end
	end
		
	def changeset(model, params, user) do
		model
		|> cast(params, ~w(shot_at shot_by comment))
		|> put_assoc(:user, user)
	end

	
end
