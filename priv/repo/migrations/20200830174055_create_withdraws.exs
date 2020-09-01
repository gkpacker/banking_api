defmodule BankingApi.Repo.Migrations.CreateWithdraws do
  use Ecto.Migration

  def change do
    create table(:withdraws) do
      add :amount_cents, :decimal, null: false
      add :user_id, references(:users, on_delete: :nothing)
      add :transaction_id, references(:transactions, on_delete: :nothing)

      timestamps()
    end

    create index(:withdraws, [:user_id, :transaction_id])
  end
end
