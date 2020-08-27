defmodule BankingApi.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :name, :string, null: false
      add :date, :date, null: false

      timestamps()
    end
  end
end
