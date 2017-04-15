defmodule Heimchen.Repo.Migrations.CreatePlaces do
  use Ecto.Migration

	# for now, no place hiarchy
  def change do
		create table(:places) do
			add :city, :string
			add :address, :text
			add :comment, :text
			add :lat, :float
			add :long, :float
			add :user_id, references(:users)
			timestamps()
		end

		create table(:places_keywords) do
			add :place_id, references(:places)
			add :keyword_id, references(:keywords)

			add :user_id, references(:users)
			timestamps()
		end

		create unique_index(:places_keywords, [:place_id, :keyword_id])
		create index(:places_keywords, [:keyword_id])

		alter table(:imagetags) do
			add :place_id, references(:places)
		end

		create index(:imagetags, [:place_id])

		create table(:places_people) do
			add :person_id, references(:people)
			add :place_id, references(:places)
			add :comment, :text
			add :start_on, :date
			add :start_precision, :int
			add :user_id, references(:users)
			timestamps()
		end

		create index(:places_people, [:place_id, :start_on])
		create index(:places_people, [:person_id, :start_on])
		
		create table(:places_items) do
			add :item_id, references(:people)
			add :place_id, references(:places)
			add :comment, :text
			add :start_on, :date
			add :start_precision, :int
			add :user_id, references(:users)
			timestamps()
		end

		create index(:places_items, [:place_id, :start_on])
		create index(:places_items, [:item_id, :start_on])
		
  end
end
