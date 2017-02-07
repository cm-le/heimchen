defmodule Heimchen.Repo.Migrations.AddImageRatio do
  use Ecto.Migration

  def change do
		alter table(:images) do
			add :orig_w, :integer
			add :orig_h, :integer
		end
  end
end
