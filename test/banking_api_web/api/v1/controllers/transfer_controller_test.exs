defmodule BankingApiWeb.Api.V1.TransferControllerTest do
  use BankingApiWeb.ConnCase
  alias BankingApiWeb.Auth.Guardian

  describe "requires authentication" do
    setup %{conn: conn} do
      {:ok, conn: put_req_header(conn, "accept", "application/json")}
    end

    test "returns unauthenticated when not logged in", %{conn: conn} do
      conn = post(conn, Routes.transfer_path(conn, :create))

      assert %{"error" => "unauthenticated"} == json_response(conn, 401)
    end
  end

  describe "transfer" do
    setup %{conn: conn} do
      user = insert(:user, email: "user@email.com")

      {:ok, user, token} = Guardian.authenticate(user.email, "password")

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)

      {:ok, conn: conn, user: user}
    end

    test "it transfers the amount to another user", %{conn: conn, user: user} do
      to_user = insert(:user)
      insert(:initial_accounts, user: user)
      insert(:initial_accounts, user: to_user)

      attrs = %{
        to: to_user.email,
        amount_cents: 20_000
      }

      conn = post(conn, Routes.transfer_path(conn, :create), transfer: attrs)

      assert %{
               "email" => "user@email.com",
               "balance" => "R$ 800.00"
             } = json_response(conn, 201)
    end

    test "can't transfer if user doesn't have suficient money", %{conn: conn} do
      to_user = insert(:user)

      attrs = %{
        to: to_user.email,
        amount_cents: 20_000
      }

      conn = post(conn, Routes.transfer_path(conn, :create), transfer: attrs)

      assert %{
               "errors" => %{"from_user" => ["doesn't have suficient money"]}
             } = json_response(conn, 422)
    end

    test "renders an error if user doesn't exists", %{conn: conn} do
      attrs = %{to: "inexistent", amount_cents: 20_000}

      conn = post(conn, Routes.transfer_path(conn, :create), transfer: attrs)

      assert %{"error" => "not_found"} = json_response(conn, 404)
    end

    test "amount must be greater than 0", %{conn: conn} do
      to_user = insert(:user)

      attrs = %{
        to: to_user.email,
        amount_cents: 0
      }

      conn = post(conn, Routes.transfer_path(conn, :create), transfer: attrs)

      assert %{
               "errors" => %{
                 "amount_cents" => ["must be greater than 0"],
                 "postings" => [
                   %{"amount" => ["must be greater than 0"]},
                   %{"amount" => ["must be greater than 0"]}
                 ]
               }
             } = json_response(conn, 422)
    end

    test "can't transfer to himself", %{conn: conn, user: user} do
      insert(:initial_accounts, user: user)

      attrs = %{
        to: user.email,
        amount_cents: 20_000
      }

      conn = post(conn, Routes.transfer_path(conn, :create), transfer: attrs)

      assert %{
               "errors" => %{"from_user" => ["can't transfer to himself"]}
             } = json_response(conn, 422)
    end
  end
end
