defmodule Heimchen.Repo.Migrations.ImagetagAdduser do
  use Ecto.Migration

  def change do
		alter table(:imagetags) do
			add :user_id, references(:users)
		end
  end
end
