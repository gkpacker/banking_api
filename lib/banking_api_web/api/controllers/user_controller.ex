defmodule BankingApiWeb.Api.UserController do
  use BankingApiWeb, :controller

  alias BankingApi.Accounts
  alias BankingApi.Accounts.User
  alias BankingApiWeb.Auth.Guardian

  action_fallback BankingApiWeb.FallbackController

  def signin(conn, %{"email" => email, "password" => password}) do
    with {:ok, user, token} <- Guardian.authenticate(email, password) do
      conn
      |> put_status(:created)
      |> render("user.json", %{user: user, token: token})
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
    {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> put_status(:created)
      |> render("user.json", %{user: user, token: token})
    end
  end
end
