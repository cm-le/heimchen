defmodule Heimchen.Repo.Migrations.PersonkeywordIndex do
  use Ecto.Migration

  def change do
		create unique_index(:people_keywords, [:person_id, :keyword_id])
		create index(:people_keywords, [:keyword_id])
  end
end
