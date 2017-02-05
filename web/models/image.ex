require IEx
defmodule Heimchen.Image do
	use Heimchen.Web, :model
	alias Heimchen.Person
	alias Heimchen.Repo

	@base_path  Application.app_dir(:heimchen, "uploads")
	@image_extensions ["jpg", "jpeg", "png"]
	
	schema "images" do
		field :original_filename, :string
		field :original_sha1, :string
		field :exif, :map
		field :comment, :string
		field :processed, :boolean

		field :orig_w, :integer
		field :orig_h, :integer
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
		{:ok, [image]}
	end

	def recently_uploaded() do
		Repo.all from i in Heimchen.Image, select:
		%{:image => i,
			:minutes => fragment("extract(minute from current_timestamp - inserted_at)::int"),
			:hours => fragment("extract(hour from current_timestamp - inserted_at)::int - 1"), # FIXME hard coded time zone
			:days => fragment("extract(day from current_timestamp - inserted_at)::int")},
			order_by: [desc: i.inserted_at], limit: 500
	end
	
	def dir(image) do
		{{y,m,_},_} = NaiveDateTime.to_erl(image.inserted_at)
		@base_path <> "/#{y}/#{m}/" <> "#{image.id}"
	end

	def orig_name(image) do
		"orig" <> String.downcase(Path.extname(image.original_filename))
	end
	
	def amend(image, file_path) do 
		target_path = dir(image)
		File.mkdir_p(target_path)
		on = orig_name(image)
		File.cp(file_path, target_path <> "/" <> on)
		System.cmd("gm",["convert", "-resize", "160x100", on, "-scale", "160x120", "thumb.jpg"], cd: target_path)
		System.cmd("gm",["convert", "-resize", "640x480", on, "-scale", "640x480", "medium.jpg"], cd: target_path)
		System.cmd("gm",["convert", "-resize", "1280x1024", on,"-scale", "1280x1024", "large.jpg"], cd: target_path)
		{checksum, _} = System.cmd("sha1sum", [on], cd: target_path)
		Repo.update(changeset(image, %{:processed => true, :original_sha1 => hd(String.split(checksum, " "))}))
		{output, _} = System.cmd("gm", ["identify", "-format", "%w %h", on], cd: target_path)
		[w,h]=String.split(String.trim(output), " ")
		Repo.update(changeset(image,%{orig_w: w, orig_h: h}))
		{output, _} = System.cmd("gm", ["identify", "-format", "%[EXIF:*]", on], cd: target_path)
		if (String.length(output) > 5) do
			Repo.update(changeset(image,
						%{exif: (for s <- String.split(output, "\n", trim: true), into: %{}, do:
								 List.to_tuple(String.split(s, "=", parts: 2)))}))
		end
	end
	
	def create(%{"file" => file, "comment" => comment}, user) do
		{dirname, basename, extension} =
		  {Path.dirname(file.path), Path.basename(file.path), Path.extname(file.filename)}
		if String.downcase(extension) == "zip" do
			{output, _} = System.cmd("unzip", ["-Z", "-1", basename], cd: dirname)
			{output2, _} = System.cmd("unzip", [basename], cd: dirname)
			String.split(output, "\n", trim: true)
			|> Enum.filter(fn(filename) ->
				Enum.member?(@image_extensions, String.downcase(Path.extension(filename))) end)
			|> Enum.map(fn(filename) ->
				create_one(dirname <> "/" <> filename, filename, comment, user) end)
			|> List.flatten()
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
		|> cast(params, ~w(original_filename original_sha1 comment exif processed orig_w orig_h))
	end

	
end
