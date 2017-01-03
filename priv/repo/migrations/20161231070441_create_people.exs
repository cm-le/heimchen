defmodule Heimchen.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
		create table(:people) do
			add :firstname, :string
			add :lastname, :string
			add :gender, :char, size: 1
			add :born_on, :date
			add :born_precision, :integer
			add :died_on, :date
			add :died_precision, :integer
			add :comment, :text
			
			add :user_id, references(:users)
			timestamps()
		end

		create table(:people_keywords) do
			add :person_id, references(:people)
			add :keyword_id, references(:keywords)

			add :user_id, references(:users)
			timestamps()
		end
		
  end
end
