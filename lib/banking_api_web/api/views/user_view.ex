defmodule BankingApiWeb.Api.UserView do
  use BankingApiWeb, :view
  alias BankingApiWeb.Api.UserView

  def render("user.json", %{user: user, token: token}) do
    %{
      email: user.email,
      token: token
    }
  end
end
