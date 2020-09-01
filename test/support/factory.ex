defmodule BankingApi.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: BankingApi.Repo

  alias BankingApi.Accounts.User
  alias BankingApi.Bank.{Account, Posting, Transaction, Withdraw}

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
      user: user
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
      user: user
    }
  end

  def transaction_factory do
    %Transaction{
      name: "Dinner",
      date: ~D[2000-03-10]
    }
  end

  def debit_factory(attrs) do
    account = Map.get(attrs, :account, insert(:debit_account))
    transaction = Map.get(attrs, :transaction, insert(:transaction))
    amount = Map.get(attrs, :amount, 1000)

    %Posting{
      amount: amount,
      type: "debit",
      account: account,
      transaction: transaction
    }
  end

  def credit_factory(attrs) do
    account = Map.get(attrs, :account, insert(:credit_account))
    transaction = Map.get(attrs, :transaction, insert(:transaction))
    amount = Map.get(attrs, :amount, 1000)

    %Posting{
      amount: amount,
      type: "credit",
      account: account,
      transaction: transaction
    }
  end

  def withdraw_factory(attrs) do
    user = Map.get(attrs, :user, insert(:user))
    amount_cents = Map.get(attrs, :amount_cents, 50_000)
    insert(:debit_account, name: Account.checking_account_name(), user: user)

    insert(
      :credit_account,
      type: "equity",
      contra: true,
      name: Account.drawings_account_name(),
      user: user
    )

    %Withdraw{
      amount_cents: amount_cents,
      user: user
    }
  end
end
