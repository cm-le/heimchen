defmodule Heimchen.Repo.Migrations.AddAttachment do
  use Ecto.Migration

  def change do
		alter table(:images) do
			add :attachment_filename, :string
			add :attachment_filesize, :bigint
		end
  end
end
