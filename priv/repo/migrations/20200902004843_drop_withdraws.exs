defmodule BankingApi.Repo.Migrations.DropWithdraws do
  use Ecto.Migration

  def change do
    drop_if_exists table(:withdraws)
  end
end
