defmodule BankingApiWeb.Api.UserView do
  use BankingApiWeb, :view

  def render("user.json", %{user: user, token: token}) do
    %{
      email: user.email,
      token: token
    }
  end
end
