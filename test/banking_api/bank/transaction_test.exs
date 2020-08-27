defmodule BankingApi.Bank.TransactionTest do
  use BankingApi.DataCase, async: true
  alias BankingApi.Bank.Transaction

  describe "Transaction.changeset/2" do
    @without_postings %{name: "Name", date: ~D[2000-03-10]}
    @invalid_attrs %{name: nil, date: nil}

    test "isn't valid without postings" do
      changeset = Transaction.changeset(%Transaction{}, @without_postings)

      assert "can't be blank" in errors_on(changeset).postings
    end

    test "isn't valid without name and date" do
      changeset = Transaction.changeset(%Transaction{}, @invalid_attrs)

      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).date
    end

    test "is valid when credits and debits postings balance" do
      credit_account = insert(:account, name: "Restaurant", type: "liability")
      debit_account = insert(:account, name: "Checking", type: "asset")
      date = Date.utc_today()

      params = %{
        name: "Dinner",
        date: date,
        postings: [
          %{type: "debit", amount: 1000, account_id: credit_account.id},
          %{type: "credit", amount: 1000, account_id: debit_account.id}
        ]
      }

      changeset = Transaction.changeset(%Transaction{}, params)

      assert changeset.valid?
    end

    test "is valid with many postings when credits and debits balance" do
      credit_account = insert(:account, name: "Restaurant", type: "liability")
      debit_account = insert(:account, name: "Checking", type: "asset")
      date = Date.utc_today()

      params = %{
        name: "Dinner",
        date: date,
        postings: [
          %{type: "debit", amount: 500, account_id: credit_account.id},
          %{type: "debit", amount: 500, account_id: credit_account.id},
          %{type: "credit", amount: 600, account_id: debit_account.id},
          %{type: "credit", amount: 400, account_id: debit_account.id}
        ]
      }

      changeset = Transaction.changeset(%Transaction{}, params)

      assert changeset.valid?
    end

    test "isn't valid when credits and debits doesn't balance" do
      credit_account = insert(:account, name: "Restaurant", type: "liability")
      debit_account = insert(:account, name: "Checking", type: "asset")
      date = Date.utc_today()

      params = %{
        name: "Dinner",
        date: date,
        postings: [
          %{type: "debit", amount: 1000, account_id: credit_account.id},
          %{type: "credit", amount: 1100, account_id: debit_account.id}
        ]
      }

      changeset = Transaction.changeset(%Transaction{}, params)

      assert "credits and debits must balance" in errors_on(changeset).postings
    end
  end
end
