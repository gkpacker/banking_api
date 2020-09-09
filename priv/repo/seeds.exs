# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     BankingApi.Repo.insert!(%BankingApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias BankingApi.Bank
alias BankingApi.Accounts

if Mix.env() in [:dev, :production] do
  {:ok, user} = Accounts.create_user(%{email: "user@bank.com", password: "password"})

  {:ok, another_user} =
    Accounts.create_user(%{email: "another_user@bank.com", password: "password"})

  Bank.give_initial_credits_to_user(user)
  Bank.create_withdraw(user, %{"amount_cents" => 20_000})
  Bank.create_transfer(user, another_user, %{"amount_cents" => 40_000})

  Bank.give_initial_credits_to_user(another_user)
  Bank.create_withdraw(another_user, %{"amount_cents" => 30_000})
  Bank.create_transfer(another_user, user, %{"amount_cents" => 50_000})
end
