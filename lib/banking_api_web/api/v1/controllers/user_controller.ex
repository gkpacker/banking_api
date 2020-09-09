defmodule BankingApiWeb.Api.V1.UserController do
  use BankingApiWeb, :controller

  alias BankingApi.Accounts
  alias BankingApi.Accounts.User
  alias BankingApi.Bank
  alias BankingApi.Bank.Transaction
  alias BankingApiWeb.Auth.Guardian

  action_fallback BankingApiWeb.Api.V1.FallbackController

  def signin(conn, %{"email" => email, "password" => password}) do
    with {:ok, user, token} <- Guardian.authenticate(email, password),
         user <- Bank.calculate_user_balance(user) do
      conn
      |> put_status(:created)
      |> put_resp_content_type("application/json")
      |> render("user.json", %{user: user, token: token})
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user),
         {:ok, %Transaction{to_user: user}} <- Bank.give_initial_credits_to_user(user) do
      conn
      |> put_status(:created)
      |> put_resp_content_type("application/json")
      |> render("user.json", %{user: user, token: token})
    end
  end
end
