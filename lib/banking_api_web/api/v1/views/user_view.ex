defmodule BankingApiWeb.Api.V1.UserView do
  use BankingApiWeb, :view

  def render("user.json", %{user: user, token: token}) do
    formatted_balance =
      user.balance
      |> Decimal.div(100)
      |> Decimal.round(2)

    %{
      email: user.email,
      token: token,
      balance: "R$ #{formatted_balance}"
    }
  end

  def render("user.json", %{user: user}) do
    formatted_balance =
      user.balance
      |> Decimal.div(100)
      |> Decimal.round(2)

    %{
      email: user.email,
      balance: "R$ #{formatted_balance}"
    }
  end
end
