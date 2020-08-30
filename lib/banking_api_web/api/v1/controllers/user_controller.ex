defmodule BankingApiWeb.Api.V1.UserController do
  use BankingApiWeb, :controller

  alias BankingApi.Accounts
  alias BankingApi.Accounts.User
  alias BankingApi.Bank
  alias BankingApi.Bank.Account
  alias BankingApiWeb.Auth.Guardian

  action_fallback BankingApiWeb.Api.V1.FallbackController

  def signin(conn, %{"email" => email, "password" => password}) do
    with {:ok, user, token} <- Guardian.authenticate(email, password) do
      conn
      |> put_status(:created)
      |> put_resp_content_type("application/json")
      |> render("user.json", %{user: user, token: token})
    end
  end

  def create(conn, %{"user" => user_params}) do
    initial_accounts = [
      %{name: Account.drawings_account_name(), type: "equity", contra: true},
      %{name: Account.payable_account_name(), type: "liability"},
      %{name: Account.checking_account_name(), type: "asset"},
      %{name: Account.initial_credits_account_name(), type: "equity"},
      %{name: Account.receivable_account_name(), type: "equity"}
    ]

    user_params = Map.put(user_params, "accounts", initial_accounts)

    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      Bank.give_initial_credits_to_user(user)

      conn
      |> put_status(:created)
      |> put_resp_content_type("application/json")
      |> render("user.json", %{user: user, token: token})
    end
  end
end
