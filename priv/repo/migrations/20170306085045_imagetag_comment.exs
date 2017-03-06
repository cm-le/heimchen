defmodule Heimchen.Repo.Migrations.ImagetagComment do
  use Ecto.Migration

  def change do
		alter table(:imagetags) do
			add :comment, :text
		end

  end
end
