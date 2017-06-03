defmodule Heimchen.Repo.Migrations.AddRelatives do
  use Ecto.Migration

  def change do
		create table(:relatives) do
			add :person1_id, references(:people)
			add :person2_id, references(:people)
			add :relname, :string
			add :relname_back, :string

			add :user_id, references(:users)
			timestamps()
		end

		create index(:relatives, :person1_id)
		create index(:relatives, :person2_id)
		
  end
end
