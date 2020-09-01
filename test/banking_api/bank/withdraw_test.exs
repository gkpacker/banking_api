defmodule BankingApi.Bank.WithdrawTest do
  use BankingApi.DataCase, async: true
  alias BankingApi.Bank.{Account, Withdraw}

  describe "Withdraw.changeset/2" do
    test "it's valid when user accounts balance" do
      user = insert(:user)
      checking = insert(:debit_account, name: Account.checking_account_name(), user: user)
      equity = insert(:credit_account, type: "equity", user: user)
      insert(:debit, amount: 100_000, account: checking)
      insert(:credit, amount: 100_000, account: equity)

      insert(
        :credit_account,
        type: "equity",
        contra: true,
        name: Account.drawings_account_name(),
        user: user
      )

      changeset = Withdraw.changeset(%Withdraw{}, %{amount_cents: 50_000, user_id: user.id})

      assert changeset.valid?
    end

    test "it isn's valid when user doesn't have suficient cash" do
      user = insert(:user)
      insert(:debit_account, name: Account.checking_account_name(), user: user)

      insert(:credit_account,
        type: "equity",
        contra: true,
        name: Account.drawings_account_name(),
        user: user
      )

      changeset = Withdraw.changeset(%Withdraw{}, %{amount_cents: 50_000, user_id: user.id})

      refute changeset.valid?
      assert "doesn't have suficient money" in errors_on(changeset).user
    end

    test "creates a withdraw transaction when it's valid" do
      user = insert(:user)
      checking = insert(:debit_account, name: Account.checking_account_name(), user: user)
      equity = insert(:credit_account, type: "equity", user: user)
      insert(:debit, amount: 100_000, account: checking)
      insert(:credit, amount: 100_000, account: equity)

      drawings =
        insert(
          :credit_account,
          type: "equity",
          contra: true,
          name: Account.drawings_account_name(),
          user: user
        )

      withdraw_amount = 50_000

      changeset =
        Withdraw.changeset(%Withdraw{}, %{amount_cents: withdraw_amount, user_id: user.id})

      assert changeset.changes.transaction.valid?

      assert [
               %Ecto.Changeset{changes: %{type: "credit"}} = credit_changeset,
               %Ecto.Changeset{changes: %{type: "debit"}} = debit_changeset
             ] = changeset.changes.transaction.changes.postings

      assert credit_changeset.changes.amount == Decimal.new(withdraw_amount)
      assert debit_changeset.changes.amount == Decimal.new(withdraw_amount)
      assert credit_changeset.changes.account_id == checking.id
      assert debit_changeset.changes.account_id == drawings.id
    end
  end
end
