defmodule Heimchen.Repo.Migrations.CreateKeywords do
  use Ecto.Migration

  def change do
		create table(:keywords) do
			add :category, :string
			add :name, :string
			add :comment, :text
			add :user_id, references(:users)

			add :for_person, :boolean
			add :for_place, :boolean
			
			add :for_photo_item, :boolean
			add :for_film_item, :boolean
			add :for_event_item, :boolean
			add :for_thing_item, :boolean

			timestamps()
		end

		create unique_index(:keywords, [:category, :name])
		
  end
end
