defmodule Heimchen.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
		create table(:images) do
			add :original_filename, :string
			add :exif, :map
			add :ratio_x_by_y, :real
			add :pathname_orig, :string
			add :pathname_thumb, :string
			add :pathname_medium, :string
			add :pathname_large, :string
			add :comment, :text
			add :shot_at, :timestamp
			add :shot_by, :string
			
			add :user_id, references(:users)
			timestamps()
		end

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
