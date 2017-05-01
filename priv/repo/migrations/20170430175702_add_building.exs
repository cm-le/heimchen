defmodule Heimchen.Repo.Migrations.AddBuilding do
  use Ecto.Migration

  def change do
		alter table(:places) do
			add :building, :string
			add :housenr, :string
		end
  end
end
