defmodule BankingApiWeb.Api.V1.TransferController do
  use BankingApiWeb, :controller
  alias BankingApi.Accounts
  alias BankingApi.Bank
  alias BankingApi.Bank.Transaction
  alias BankingApiWeb.Api.V1.UserView
  import Guardian.Plug

  action_fallback BankingApiWeb.Api.V1.FallbackController

  def create(conn, %{"transfer" => transfer_params}) do
    user = current_resource(conn)
    to_user_email = Map.get(transfer_params, "to")

    with {:ok, to_user} <- Accounts.get_user_by_email(to_user_email),
         {:ok, %Transaction{from_user: user}} <-
           Bank.create_transfer(user, to_user, transfer_params) do
      conn
      |> put_status(:created)
      |> put_resp_content_type("application/json")
      |> put_view(UserView)
      |> render("user.json", %{user: user})
    end
  end
end
