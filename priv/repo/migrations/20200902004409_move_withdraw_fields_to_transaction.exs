defmodule BankingApi.Repo.Migrations.MoveWithdrawFieldsToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :type, :string, null: false
      add :from_user_id, references(:users, on_delete: :nothing)
      add :to_user_id, references(:users, on_delete: :nothing)

      add :amount_cents, :decimal, null: false
    end

    create index(:transactions, [:from_user_id])
    create index(:transactions, [:to_user_id])
  end
end
