defmodule BankingApiWeb.Api.V1.UserView do
  use BankingApiWeb, :view
  alias BankingApi.Bank

  def render("user.json", %{user: user, token: token}) do
    formatted_balance = Bank.amount_from_cents(user.balance)

    %{
      email: user.email,
      token: token,
      balance: "R$ #{formatted_balance}"
    }
  end

  def render("user.json", %{user: user}) do
    formatted_balance = Bank.amount_from_cents(user.balance)

    %{
      email: user.email,
      balance: "R$ #{formatted_balance}"
    }
  end
end
