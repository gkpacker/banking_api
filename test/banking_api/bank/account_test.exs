defmodule BankingApi.Bank.AccountTest do
  use BankingApi.DataCase, async: true
  alias BankingApi.Bank.Account

  describe "Account.by_name" do
    test "returns accounts with queried name" do
      cash_account = insert(:debit_account, name: "Cash")
      insert(:debit_account)

      assert [account_by_name] =
               Account
               |> Account.by_name("Cash")
               |> Repo.all()

      assert cash_account.id == account_by_name.id
    end
  end

  describe "Account.by_user" do
    test "returns accounts with queried user" do
      user = insert(:user)
      insert(:debit_account, user: user)
      insert(:debit_account)

      assert [account_by_user] =
               Account
               |> Account.by_user(user)
               |> Repo.all()

      assert user.id == account_by_user.user_id
    end
  end

  describe "Account.balance/1" do
    test "sub credits from debits when it's a debit account" do
      account = insert(:debit_account)
      insert(:debit, amount: 11_000, account: account)
      insert(:credit, amount: 1000, account: account)

      assert Account.balance(account) == Decimal.new(10_000)
    end

    test "sub debits from credits when it's a contra debit account" do
      account = insert(:debit_account, contra: true)
      insert(:debit, amount: 11_000, account: account)
      insert(:credit, amount: 1000, account: account)

      assert Account.balance(account) == Decimal.new(-10_000)
    end

    test "sub debits from credits when it's a credit account" do
      account = insert(:credit_account)
      insert(:debit, amount: 1000, account: account)
      insert(:credit, amount: 10_000, account: account)

      assert Account.balance(account) == Decimal.new(9_000)
    end

    test "sub credits from debits when it's a contra credit account" do
      account = insert(:credit_account, contra: true)
      insert(:debit, amount: 1000, account: account)
      insert(:credit, amount: 11_000, account: account)

      assert Account.balance(account) == Decimal.new(-10_000)
    end

    test "calculates the balance for given accounts when it's a list" do
      credit_account = insert(:credit_account)
      insert(:credit, amount: 1000, account: credit_account)
      debit_account = insert(:debit_account)
      insert(:debit, amount: 10_000, account: debit_account)

      assert Account.balance([credit_account, debit_account]) == Decimal.new(9_000)
    end

    test "returns 0 when it's an empty list" do
      assert Account.balance([]) == Decimal.new(0)
    end
  end
end
