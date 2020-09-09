defmodule BankingApi.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: BankingApi.Repo

  alias BankingApi.Accounts.User
  alias BankingApi.Bank.{Account, Posting, Transaction}

  def user_factory(attrs) do
    default_email = sequence(:email, &"user#{&1}@email.com")
    email = Map.get(attrs, :email, default_email)
    password = Map.get(attrs, :password, "password")

    %User{
      email: email,
      encrypted_password: Bcrypt.hash_pwd_salt(password)
    }
  end

  def credit_account_factory(attrs) do
    user = Map.get(attrs, :user, insert(:user))
    contra = Map.get(attrs, :contra, false)
    name = Map.get(attrs, :name, "Accounts Payable")
    type = Map.get(attrs, :type, "liability")

    %Account{
      name: name,
      type: type,
      contra: contra,
      user_id: user.id
    }
  end

  def debit_account_factory(attrs) do
    user = Map.get(attrs, :user, insert(:user))
    contra = Map.get(attrs, :contra, false)
    name = Map.get(attrs, :name, "Checking")

    %Account{
      name: name,
      type: "asset",
      contra: contra,
      user_id: user.id
    }
  end

  def transaction_factory do
    %Transaction{
      name: "Dinner",
      date: ~D[2000-03-10],
      amount_cents: 1000,
      type: "withdraw"
    }
  end

  def deposit_factory(attrs) do
    user = Map.get(attrs, :user, insert(:user))
    account = Map.get(attrs, :account, insert(:debit_account, user: user))

    credit_account =
      Map.get(attrs, :credit_account, insert(:credit_account, user: user, type: "equity"))

    %Transaction{
      name: "Deposit",
      date: Date.utc_today(),
      amount_cents: 100_000,
      to_user_id: user.id,
      type: "deposit",
      postings: [
        %{amount: 100_000, account_id: account.id, type: "debit"},
        %{amount: 100_000, account_id: credit_account.id, type: "credit"}
      ]
    }
  end

  def debit_factory(attrs) do
    account = Map.get(attrs, :account, insert(:debit_account))
    transaction = Map.get(attrs, :transaction, insert(:transaction))
    amount = Map.get(attrs, :amount, 1000)

    %Posting{
      amount: amount,
      type: "debit",
      account_id: account.id,
      transaction_id: transaction.id
    }
  end

  def credit_factory(attrs) do
    account = Map.get(attrs, :account, insert(:credit_account))
    transaction = Map.get(attrs, :transaction, insert(:transaction))
    amount = Map.get(attrs, :amount, 1000)

    %Posting{
      amount: amount,
      type: "credit",
      account_id: account.id,
      transaction_id: transaction.id
    }
  end

  def initial_accounts_factory(attrs) do
    user_balance = Map.get(attrs, :user_balance, 100_000)
    user = Map.get(attrs, :user, insert(:user))
    checking = insert(:debit_account, name: Account.checking_account_name(), user: user)

    equity =
      insert(:credit_account,
        name: Account.initial_credits_account_name(),
        type: "equity",
        user: user
      )

    insert(:debit, amount: user_balance, account: checking)
    insert(:credit, amount: user_balance, account: equity)

    build(
      :credit_account,
      type: "equity",
      contra: true,
      name: Account.drawings_account_name(),
      user: user
    )
  end
end
