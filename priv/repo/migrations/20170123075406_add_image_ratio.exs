defmodule Heimchen.Repo.Migrations.AddImageRatio do
  use Ecto.Migration

  def change do
		alter table(:places) do
			add :building, :string
		end
  end
end
