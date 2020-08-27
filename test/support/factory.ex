defmodule BankingApi.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: BankingApi.Repo

  alias BankingApi.Accounts.User
  alias BankingApi.Bank.{Transaction, Posting, Account}

  def user_factory do
    email = sequence(:email, &"user#{&1}@email.com")

    %User{
      email: email,
      password: "123123"
    }
  end

  def account_factory do
    user = insert(:user)

    %Account{
      name: "Checking",
      type: "asset",
      user_id: user.id
    }
  end

  def transaction_factory do
    %Transaction{
      name: "Checking",
      date: ~D[2000-03-10]
    }
  end

  def debit_factory do
    account = insert(:account)
    transaction = insert(:transaction)

    %Posting{
      amount: 1000,
      type: "debit",
      account: account,
      transaction: transaction
    }
  end

  def credit_factory do
    account = insert(:account)
    transaction = insert(:transaction)

    %Posting{
      amount: 1000,
      type: "credit",
      account: account,
      transaction: transaction
    }
  end
end
