defmodule BankingApiWeb.Api.V1.WithdrawController do
  use BankingApiWeb, :controller
  alias BankingApi.Bank
  alias BankingApiWeb.Api.V1.UserView
  import Guardian.Plug

  action_fallback BankingApiWeb.Api.V1.FallbackController

  def create(conn, %{"withdraw" => withdraw_params}) do
    user = current_resource(conn)
    withdraw_params = Map.put(withdraw_params, "user_id", user.id)

    with {:ok, withdraw} <- Bank.create_withdraw(withdraw_params) do
      conn
      |> put_status(:created)
      |> put_resp_content_type("application/json")
      |> put_view(UserView)
      |> render("user.json", %{user: withdraw.user})
    end
  end
end
