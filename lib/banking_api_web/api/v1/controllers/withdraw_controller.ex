defmodule BankingApiWeb.Api.V1.WithdrawController do
  use BankingApiWeb, :controller
  alias BankingApi.{Bank, Email, Mailer}
  alias BankingApi.Bank.Withdraw
  alias BankingApiWeb.Api.V1.UserView
  import Guardian.Plug

  action_fallback BankingApiWeb.Api.V1.FallbackController

  def create(conn, %{"withdraw" => withdraw_params}) do
    user = current_resource(conn)
    withdraw_params = Map.put(withdraw_params, "user_id", user.id)

    with {:ok, %Withdraw{user: user} = withdraw} <- Bank.create_withdraw(withdraw_params) do
      withdraw_email =
        Email.user_withdraw_html_email(
          user.email,
          user.balance,
          withdraw.amount_cents
        )

      Mailer.deliver_later(withdraw_email)

      conn
      |> put_status(:created)
      |> put_resp_content_type("application/json")
      |> put_view(UserView)
      |> render("user.json", %{user: user})
    end
  end
end
