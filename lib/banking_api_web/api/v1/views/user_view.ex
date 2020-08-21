defmodule BankingApiWeb.Api.V1.UserView do
  use BankingApiWeb, :view

  def render("user.json", %{user: user, token: token}) do
    %{
      email: user.email,
      token: token
    }
  end
end
