require IEx
defmodule Heimchen.Image do
	use Heimchen.Web, :model
	alias Heimchen.Person
	alias Heimchen.Repo

	@base_path  Application.app_dir(:heimchen, "uploads")
	
	schema "images" do
		field :original_filename, :string
		field :original_sha1, :string
		field :exif, :map
		field :comment, :string
		field :processed, :boolean
		
		belongs_to :user, Heimchen.User
		has_many :imagetags, Heimchen.Imagetag
		timestamps
	end


	def create_one(file_path,original_filename, comment, user) do
		# IEx.pry
		{:ok, image} = Repo.insert(changeset(%Heimchen.Image{},
					%{:comment => comment,
						:original_filename => original_filename}, user))
		spawn fn -> amend(image, file_path) end
		{:ok, image}
	end

	def dir(image) do
		{{y,m,_},_} = NaiveDateTime.to_erl(image.inserted_at)
		@base_path <> "/#{y}/#{m}/" <> "#{image.id}"
	end
	
	def amend(image, file_path) do 
		target_path = dir(image)
		File.mkdir_p(target_path)
		orig_name = "orig" <> String.downcase(Path.extname(image.original_filename))
		File.cp(file_path, target_path <> "/" <> orig_name)
		System.cmd("gm",["convert", "-resize", "160x100", orig_name, "-scale", "160x100", "thumb.jpg"], cd: target_path)
		System.cmd("gm",["convert", "-resize", "640x480", orig_name, "-scale", "640x480", "medium.jpg"], cd: target_path)
		System.cmd("gm",["convert", "-resize", "1280x1024", orig_name,"-scale", "1280x1024", "large.jpg"], cd: target_path)
		{checksum, _} = System.cmd("sha1sum", [orig_name], cd: target_path)
		IEx.pry
		Repo.update(changeset(image, %{:processed => true, :original_sha1 => hd(String.split(checksum, " "))}))
		{output, _} = System.cmd("gm", ["identify", "-format", "\"%[EXIF:*]\"", orig_name], cd: target_path)
		if (String.length(output) > 0) do
			Repo.update(changeset(image,
						%{exif: (for s <- String.split(output, "\n", trim: true), into: %{}, do:
								 List.to_tuple(String.split(s, "=", parts: 2)))}))
		end
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
		changeset(model, params)
		|> put_assoc(:user, user)
	end


	def changeset(model, params) do
		model
		|> cast(params, ~w(original_filename original_sha1 comment exif processed))
	end

	
end
