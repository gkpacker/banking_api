defmodule BankingApi.BankTest do
  use BankingApi.DataCase, async: true

  alias BankingApi.Bank
  alias BankingApi.Bank.{Account, Posting, Transaction, Withdraw}

  describe "accounts" do
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

      assert [first_account] = Bank.list_accounts()
      assert first_account.id == account.id
    end

    test "get_account!/1 returns the account with given id" do
      account = insert(:debit_account)

      assert Bank.get_account!(account.id).id == account.id
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
      assert account.id == Bank.get_account!(account.id).id
    end

    test "update_account/2 with invalid type returns error changeset" do
      account = insert(:debit_account)

      assert {:error, %Ecto.Changeset{}} = Bank.update_account(account, @invalid_type_attrs)
      assert account.id == Bank.get_account!(account.id).id
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

    test "get_and_lock_user_account_by_name!/1 returns a locked account by name" do
      user = insert(:user)
      account = insert(:debit_account, name: "Checking", user: user)
      insert(:debit_account, name: "Cash", user: user)
      user_account_by_name = Bank.get_and_lock_user_account_by_name!(user, "Checking")

      assert account.id == user_account_by_name.id
    end
  end

  describe "transactions" do
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
      assert debit_posting.account.id == credit_account.id
      assert credit_posting.account.id == debit_account.id
    end

    test "give_initial_credits_to_user/1 gives R$ 1000,00 credits to user" do
      user = insert(:user)

      insert(
        :credit_account,
        type: "equity",
        name: Account.initial_credits_account_name(),
        user: user
      )

      insert(
        :debit_account,
        name: Account.checking_account_name(),
        user: user
      )

      assert {:ok, user_with_balance} = Bank.give_initial_credits_to_user(user)
      assert user_with_balance.balance == Decimal.new(100_000)
    end
  end

  describe "postings" do
    test "list_postings/0 returns all postings" do
      posting = insert(:credit)

      assert [first_posting] = Bank.list_postings()
      assert first_posting.id == posting.id
    end

    test "get_posting!/1 returns the posting with given id" do
      posting = insert(:debit)

      assert Bank.get_posting!(posting.id).id == posting.id
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

  describe "users" do
    test "calculate_user_balance/1 returns user's assets minus liabilities" do
      user = insert(:user)
      asset = insert(:debit_account, user: user)
      liability = insert(:credit_account, type: "liability", user: user)

      restaurant_expenses =
        insert(:credit_account, name: "Restaurant", type: "liability", user: user)

      insert(:debit, amount: 100_000, account: asset)
      insert(:credit, amount: 10_000, account: liability)
      insert(:credit, amount: 5_000, account: restaurant_expenses)

      assert Bank.calculate_user_balance(user).balance == Decimal.new(100_000 - 10_000 - 5_000)
    end

    test "calculate_user_balance/1 only calculates accounts' balances from given user" do
      user = insert(:user)
      asset = insert(:debit_account, user: user)
      liability = insert(:credit_account, type: "liability", user: user)
      insert(:debit, amount: 100_000, account: asset)
      insert(:credit, amount: 10_000, account: liability)

      another_user = insert(:user)

      assert Bank.calculate_user_balance(another_user).balance == Decimal.new(0)
    end
  end

  describe "withdraws" do
    test "list_withdraws/0 returns all withdraws" do
      withdraw = insert(:withdraw)
      assert [first_withdraw] = Bank.list_withdraws()
      assert first_withdraw.id == withdraw.id
    end

    test "get_withdraw!/1 returns the withdraw with given id" do
      withdraw = insert(:withdraw)
      assert Bank.get_withdraw!(withdraw.id).id == withdraw.id
    end

    test "create_withdraw/1 removes the drawn amount from user's balance" do
      user = insert(:user)
      checking = insert(:debit_account, name: Account.checking_account_name(), user: user)
      equity = insert(:credit_account, type: "equity", user: user)
      insert(:debit, amount: 70_000, account: checking)
      insert(:credit, amount: 70_000, account: equity)

      insert(
        :credit_account,
        type: "equity",
        contra: true,
        name: Account.drawings_account_name(),
        user: user
      )

      attrs = %{amount_cents: 50_000, user_id: user.id}

      assert {:ok, %Withdraw{} = withdraw} = Bank.create_withdraw(attrs)
      assert withdraw.amount_cents == Decimal.new(50_000)
      assert withdraw.user.balance == Decimal.new(20_000)
      assert withdraw.user.id == user.id
      assert Bank.calculate_user_balance(user).balance == Decimal.new(20_000)
    end

    test "create_withdraw/1 doesn't change user balance if it wasn't created" do
      user = insert(:user)
      checking = insert(:debit_account, name: Account.checking_account_name(), user: user)
      equity = insert(:credit_account, type: "equity", user: user)
      insert(:debit, amount: 30_000, account: checking)
      insert(:credit, amount: 30_000, account: equity)

      attrs = %{amount_cents: 50_000, user_id: user.id}

      {:error, %Ecto.Changeset{} = changeset} = Bank.create_withdraw(attrs)
      refute changeset.valid?
      assert Bank.calculate_user_balance(user).balance == Decimal.new(30_000)
    end
  end

  test "amount_from_cents/1 returns a decimal with 2 digits precision" do
    assert Bank.amount_from_cents(100_000) == Decimal.round(Decimal.new(1000), 2)
  end

  test "amount_from_cents/1 works with decimals" do
    assert Bank.amount_from_cents(Decimal.new(100_000)) == Decimal.round(Decimal.new(1000), 2)
  end

  test "amount_to_cents/1 returns an amount in cents" do
    assert Bank.amount_to_cents(1000) == Decimal.new(100_000)
  end
end
