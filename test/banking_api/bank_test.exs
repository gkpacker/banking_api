defmodule BankingApi.BankTest do
  use BankingApi.DataCase

  alias BankingApi.Bank

  describe "accounts" do
    alias BankingApi.Bank.Account

    @valid_attrs %{contra: false, name: "Checking", type: "asset", user_id: 1}
    @update_attrs %{contra: true, name: "Drawing", type: "asset"}
    @invalid_attrs %{contra: nil, name: nil, type: nil}
    @invalid_type_attrs %{contra: false, name: "Checking", type: "invalid"}

    setup %{} do
      user = insert(:user)

      {:ok, user: user, valid_attrs: %{@valid_attrs | user_id: user.id}}
    end

    test "list_accounts/0 returns all accounts" do
      account = insert(:debit_account)
      assert Bank.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = insert(:debit_account)
      assert Bank.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(valid_attrs)
      assert account.contra == false
      assert account.name == "Checking"
      assert account.type == "asset"
    end

    test "create_account/1 with asset type is valid", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(%{valid_attrs | type: "asset"})
      assert account.type == "asset"
    end

    test "create_account/1 with liability type is valid", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(%{valid_attrs | type: "liability"})
      assert account.type == "liability"
    end

    test "create_account/1 with equity type is valid", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(%{valid_attrs | type: "equity"})
      assert account.type == "equity"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_account(@invalid_attrs)
    end

    test "create_account/1 with invalid type returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_account(@invalid_type_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = insert(:debit_account)
      assert {:ok, %Account{} = account} = Bank.update_account(account, @update_attrs)
      assert account.contra == true
      assert account.name == "Drawing"
      assert account.type == "asset"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = insert(:debit_account)
      assert {:error, %Ecto.Changeset{}} = Bank.update_account(account, @invalid_attrs)
      assert account == Bank.get_account!(account.id)
    end

    test "update_account/2 with invalid type returns error changeset" do
      account = insert(:debit_account)
      assert {:error, %Ecto.Changeset{}} = Bank.update_account(account, @invalid_type_attrs)
      assert account == Bank.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = insert(:debit_account)
      assert {:ok, %Account{}} = Bank.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Bank.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = insert(:debit_account)
      assert %Ecto.Changeset{} = Bank.change_account(account)
    end
  end

  describe "transactions" do
    alias BankingApi.Bank.{Posting, Transaction}

    test "list_transactions/0 returns all transactions" do
      transaction = insert(:transaction)

      assert Bank.list_transactions() == [transaction]
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = insert(:transaction)

      assert Bank.get_transaction!(transaction.id) == transaction
    end

    test "create_transaction/1 creates associated posts" do
      credit_account = insert(:credit_account)
      debit_account = insert(:debit_account)
      date = Date.utc_today()

      params = %{
        name: "Dinner",
        date: date,
        postings: [
          %{type: "debit", amount: 1000, account_id: credit_account.id},
          %{type: "credit", amount: 1000, account_id: debit_account.id}
        ]
      }

      assert {:ok, %Transaction{} = transaction} = Bank.create_transaction(params)
      assert transaction.date == date
      assert transaction.name == "Dinner"

      assert [
               %Posting{type: "debit"} = debit_posting,
               %Posting{type: "credit"} = credit_posting
             ] = transaction.postings

      assert debit_posting.amount == Decimal.new(1000)
      assert credit_posting.amount == Decimal.new(1000)
      assert debit_posting.account == credit_account
      assert credit_posting.account == debit_account
    end
  end

  describe "postings" do
    alias BankingApi.Bank.Posting

    test "list_postings/0 returns all postings" do
      posting = insert(:credit)

      assert Bank.list_postings() == [posting]
    end

    test "get_posting!/1 returns the posting with given id" do
      posting = insert(:debit)

      assert Bank.get_posting!(posting.id) == posting
    end

    test "sum_account_credits/1 sum account credit postings" do
      account = insert(:debit_account)
      insert(:credit, amount: 2000, account: account)
      insert(:credit, amount: 2000, account: account)
      insert(:debit, amount: 2000, account: account)

      assert Bank.sum_account_credits(account) == Decimal.new(4000)
    end

    test "sum_account_credits/1 returns 0 if account doesn't have credits" do
      account = insert(:debit_account)

      assert Bank.sum_account_credits(account) == Decimal.new(0)
    end

    test "sum_account_debits/1 sum account debit postings" do
      account = insert(:debit_account)
      insert(:debit, amount: 2000, account: account)
      insert(:debit, amount: 1500, account: account)
      insert(:credit, amount: 2000, account: account)

      assert Bank.sum_account_debits(account) == Decimal.new(3500)
    end

    test "sum_account_debits/1 returns 0 if account doesn't have debits" do
      account = insert(:debit_account)

      assert Bank.sum_account_debits(account) == Decimal.new(0)
    end
  end
end
