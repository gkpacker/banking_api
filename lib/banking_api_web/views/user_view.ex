defmodule BankingApiWeb.UserView do
  use BankingApiWeb, :view
  alias BankingApiWeb.UserView

  def render("user.json", %{user: user, token: token}) do
    %{
      email: user.email,
      token: token
    }
  end
end
