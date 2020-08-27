defmodule BankingApiWeb.Api.V1.UserControllerTest do
  use BankingApiWeb.ConnCase

  alias BankingApi.Accounts

  @create_attrs %{
    email: "user@email.com",
    password: "password"
  }
  @invalid_attrs %{email: nil, password: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{
               "email" => "user@email.com",
               "token" => token
             } = json_response(conn, 201)
    end

    test "creates user with its initial accounts", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{"email" => email} = json_response(conn, 201)
      assert {:ok, user} = Accounts.get_by_email(email)

      assert [
               %{name: "Accounts receivable", type: "equity"},
               %{name: "Initial Credit", type: "equity"},
               %{name: "Checking", type: "asset"},
               %{name: "Accounts payable", type: "liability"},
               %{name: "Drawing", type: "equity", contra: true}
             ] = user.accounts
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)

      assert %{
               "errors" => %{
                 "email" => ["can't be blank"],
                 "password" => ["can't be blank"]
               }
             } == json_response(conn, 422)
    end
  end

  describe "signin user" do
    setup [:create_user]

    test "renders user when valid authentication", %{conn: conn, user: user} do
      conn =
        post(
          conn,
          Routes.user_path(conn, :signin),
          email: user.email,
          password: @create_attrs[:password]
        )

      assert %{
               "email" => "user@email.com",
               "token" => token
             } = json_response(conn, 201)
    end

    test "renders unauthorized when user not found", %{conn: conn, user: _user} do
      conn =
        post(
          conn,
          Routes.user_path(conn, :signin),
          email: "not@found.com",
          password: "password"
        )

      assert %{
               "error" => "unauthorized"
             } == json_response(conn, 401)
    end

    test "renders unauthorized when invalid authentication", %{conn: conn, user: user} do
      conn =
        post(
          conn,
          Routes.user_path(conn, :signin),
          email: user.email,
          password: "invalid_password"
        )

      assert %{
               "error" => "unauthorized"
             } == json_response(conn, 401)
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    %{user: user}
  end
end
