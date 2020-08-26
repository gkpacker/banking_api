defmodule BankingApi.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :contra, :boolean, null: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:accounts, [:user_id])
  end
end
