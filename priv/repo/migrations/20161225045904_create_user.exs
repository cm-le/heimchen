defmodule Heimchen.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
		create table(:users) do
			add :firstname, :string
			add :lastname, :string
			add :academic, :string
			add :gender, :string
			add :avatar, :binary
			add :username, :string, null: false
			add :password_hash, :string
			add :email, :string
			add :comment, :text
			add :admin, :boolean
			add :active, :boolean
			timestamps
		end

		create unique_index(:users, [:username])
		
  end
end
