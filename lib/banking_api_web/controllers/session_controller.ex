defmodule BankingApiWeb.SessionController do
  use BankingApiWeb, :controller

  alias BankingApi.Accounts
  alias BankingApi.Accounts.User
  alias BankingApiWeb.Auth.Guardian

  action_fallback BankingApiWeb.FallbackController

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    user = Guardian.Plug.current_resource(conn)

    render(conn, "new.html",
      changeset: changeset,
      action: Routes.session_path(conn, :create),
      user: user
    )
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    Guardian.authenticate(email, password)
    |> login_reply(conn)
  end

  def delete(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp login_reply({:error, error}, conn) do
    conn
    |> put_flash(:error, error)
    |> redirect(to: "/login")
  end

  defp login_reply({:ok, user, _token}, conn) do
    conn
    |> put_flash(:success, "Welcome back, #{user.email}!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: "/")
  end
end
