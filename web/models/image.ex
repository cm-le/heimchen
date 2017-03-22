require IEx
defmodule Heimchen.Image do
	use Heimchen.Web, :model
	alias Heimchen.Person
	alias Heimchen.Repo
	alias Heimchen.Imagetag

	@base_path  Application.app_dir(:heimchen, "uploads")
	@image_extensions [".jpg", ".jpeg", ".png", ".gif"]
	
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

	def resolution(zoom) do
		case zoom do
			1 -> {160,120}
			2 -> {640, 480}
			3 -> {1280, 1024}
		end
	end

	def real_resolution(image, zoom) do
		# XXX FIXME depending on orig_w and orig_h of image
		resolution(zoom)
	end
	
	def create_one(file_path,original_filename, comment, item_id, person_id, user) do
		{:ok, image} = Repo.insert(changeset(%Heimchen.Image{},
					%{:comment => comment,
						:original_filename => original_filename}, user))
		case Integer.parse(item_id) do
			{i, _} -> Imagetag.add_item_mark(i, image.id, user)
			_ -> :error
		end
		case Integer.parse(person_id) do
			{i, _} -> Imagetag.add_person_mark(i, image.id, user)
			_ -> :error
		end
		spawn fn -> amend(image, file_path) end
		image
	end

	def recently_uploaded() do
		Repo.all from i in Heimchen.Image, select:
		%{:image => i,
			:minutes => fragment("extract(minute from current_timestamp - inserted_at)::int"),
			:hours => fragment("extract(hour from current_timestamp - inserted_at)::int - 1"), # FIXME hard coded time zone
			:days => fragment("extract(day from current_timestamp - inserted_at)::int")},
			preload: [imagetags: :person],
			order_by: [desc: i.inserted_at], limit: 500
	end
	
	def dir(image) do
		{{y,m,_},_} = NaiveDateTime.to_erl(image.inserted_at)
		@base_path <> "/#{y}/#{m}/" <> "#{image.id}"
	end

	# give the dir name, but delay it, maybe gm was not ready?
	# FIXME should take timestamp into account
	def delayed_dir(image) do delayed_dir(image, 0) end
	def delayed_dir(image, delay) when delay < 30 do
		if File.exists?(dir(image) <> "/thumb.jpg") do
			dir(image)
		else
			Process.sleep(1)
			delayed_dir(image, delay+1)
		end
	end
	def delayed_dir(_, _) do :error end

	def orig_name(image) do
		"orig" <> String.downcase(Path.extname(image.original_filename))
	end
	
	def amend(image, file_path) do 
		target_path = dir(image)
		File.mkdir_p(target_path)
		on = orig_name(image)
		File.cp(file_path, target_path <> "/" <> on)
		{w1,h1} = resolution(1)
		{w2,h2} = resolution(2)
		{w3,h3} = resolution(3)
		
		System.cmd("gm",["convert", "-resize", "#{w1}x#{h1}", on, "-scale", "#{w1}x#{h1}", "thumb.jpg"], cd: target_path)
		System.cmd("gm",["convert", "-resize", "#{w2}x#{h2}", on, "-scale", "#{w2}x#{h2}", "medium.jpg"], cd: target_path)
		System.cmd("gm",["convert", "-resize", "#{w3}x#{h3}", on,"-scale",  "#{w3}x#{h3}", "large.jpg"], cd: target_path)
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
	
	def create(%{"file" => file, "comment" => comment,
							 "item_id" => item_id, "person_id" => person_id}, user) do
		{dirname, basename, extension} =
		  {Path.dirname(file.path), Path.basename(file.path), Path.extname(file.filename)}
		if String.downcase(extension) == ".zip" do
			{output, _} = System.cmd("unzip", ["-Z", "-1", basename], cd: dirname)
			{output2, _} = System.cmd("unzip", ["-o", basename], cd: dirname)
			String.split(output, "\n", trim: true)
			|> Enum.filter(fn(filename) ->
				!String.starts_with?(filename, ".") &&
					Enum.member?(@image_extensions, String.downcase(Path.extname(filename))) end)
			|> Enum.map(fn(filename) ->
				create_one(dirname <> "/" <> filename, Path.basename(filename), comment, item_id, person_id, user) end)
		else
			[create_one(file.path, file.filename, comment, item_id, person_id, user)]
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
