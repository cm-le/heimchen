defmodule Heimchen.Repo.Migrations.Items do
  use Ecto.Migration

  def change do
		create table(:itemtypes) do
			add :sid, :string
			add :name, :string
			add :has_room, :boolean
		end

		create table(:rooms) do
			add :name, :string
		end
		
		create table(:items) do
			add :name, :string
			add :comment, :text
			add :date_on, :date
			add :date_precision, :integer
			add :received_by_id, references(:people)
			add :received_comment, :text

			add :inventory, :string
			add :filenr, :string
			add :filecomment, :text

			add :itemtype_id, references(:itemtypes)
			add :user_id, references(:users)
			add :room_id, references(:rooms)
			timestamps()
		end

		create index(:items, [:room_id])

		
		create table(:item_keywords) do
			add :item_id, references(:people)
			add :keyword_id, references(:keywords)

			add :user_id, references(:users)
			timestamps()
		end

		alter table(:imagetags) do
			add :item_id, references(:items)
			add :is_primary, :boolean
		end

		create unique_index(:item_keywords, [:item_id, :keyword_id])
		create index(:item_keywords, [:keyword_id])
		create index(:imagetags, [:item_id])
		
  end
end
