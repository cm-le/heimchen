defmodule Heimchen.Repo.Migrations.AddMaiden do
  use Ecto.Migration

  def change do
		alter table(:people) do
			add :maidenname, :string
		end

  end
end
