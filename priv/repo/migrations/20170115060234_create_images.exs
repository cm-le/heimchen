defmodule Heimchen.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
		create table(:images) do
			add :filename, :string
			add :exif, :map
			add :ratio_x_by_y, :real
			add :pathname_orig, :string
			add :pathname_thumb, :string
			add :pathname_medium, :string
			add :pathname_large, :string
		end
			
  end
end
