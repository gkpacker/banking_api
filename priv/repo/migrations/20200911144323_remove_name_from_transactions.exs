defmodule BankingApi.Repo.Migrations.RemoveNameFromTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      remove :name
    end
  end
end
