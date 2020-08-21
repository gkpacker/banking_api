defmodule BankingApiWeb.UserView do
  use BankingApiWeb, :view
  alias BankingApiWeb.UserView

  def render("user.json", %{user: user}) do
    %{id: user.id,
      email: user.email,
      encrypted_password: user.encrypted_password}
  end
end
