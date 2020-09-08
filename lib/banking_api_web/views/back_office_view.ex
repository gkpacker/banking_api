defmodule BankingApiWeb.BackOfficeView do
  use BankingApiWeb, :view

  alias BankingApi.Accounts.User
  alias BankingApi.Bank

  def amount_from_cents(cents) do
    Bank.amount_from_cents(cents)
  end

  def transaction_target(%User{email: email}), do: email
  def transaction_target(nil), do: "-"
end
