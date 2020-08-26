defmodule BankingApi.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: BankingApi.Repo

  alias BankingApi.Accounts.User
  alias BankingApi.Bank.Account

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
      name: "Cash",
      type: "asset",
      user_id: user.id
    }
  end
end
