defmodule BankingApi.Repo.Migrations.CreatePostings do
  use Ecto.Migration

  def change do
    create table(:postings) do
      add :type, :string, null: false
      add :amount, :decimal, null: false
      add :account_id, references(:accounts, on_delete: :nothing)
      add :transaction_id, references(:transactions, on_delete: :nothing)

      timestamps()
    end

    create index(:postings, [:account_id])
    create index(:postings, [:transaction_id])
  end
end
