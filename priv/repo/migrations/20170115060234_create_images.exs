defmodule Heimchen.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
		create table(:images) do
			add :original_filename, :string
			add :original_sha1, :string
			add :exif, :map
			add :comment, :text

			add :processed, :boolean
			add :user_id, references(:users)
			timestamps()
		end

		create index(:images, [:inserted_at])

		create table(:imagetags) do
			add :image_id, references(:images)
			add :person_id, references(:people)
			# in the future add aditional references which can be tagges
			add :marks, :map
			timestamps()
		end

		create index(:imagetags, [:image_id])
		create index(:imagetags, [:person_id])
		
  end
end
