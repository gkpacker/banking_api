defmodule BankingApiWeb.Api.V1.WithdrawControllerTest do
  use BankingApiWeb.ConnCase
  use Bamboo.Test
  alias BankingApi.Email
  alias BankingApiWeb.Auth.Guardian

  @create_attrs %{amount_cents: 20_000}
  @invalid_attrs %{amount_cents: 0}

  describe "requires authentication" do
    setup %{conn: conn} do
      {:ok, conn: put_req_header(conn, "accept", "application/json")}
    end

    test "returns unauthenticated when not logged in", %{conn: conn} do
      conn = post(conn, Routes.withdraw_path(conn, :create), withdraw: @create_attrs)

      assert_no_emails_delivered()
      assert %{"error" => "unauthenticated"} == json_response(conn, 401)
    end
  end

  describe "create withdraw" do
    setup %{conn: conn} do
      user = insert(:user, email: "user@email.com")

      {:ok, user, token} = Guardian.authenticate(user.email, "password")

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)

      {:ok, conn: conn, user: user}
    end

    test "it removes the amount from user's account", %{conn: conn, user: user} do
      insert(:user_with_initial_accounts, user: user)
      conn = post(conn, Routes.withdraw_path(conn, :create), withdraw: @create_attrs)

      expected_email =
        Email.user_withdraw_html_email(
          user.email,
          Decimal.new(80_000),
          @create_attrs.amount_cents
        )

      assert_delivered_email(expected_email)

      assert %{
               "email" => "user@email.com",
               "balance" => "R$ 800.00"
             } = json_response(conn, 201)
    end

    test "renders errors when user doesn't have suficient money", %{conn: conn} do
      conn = post(conn, Routes.withdraw_path(conn, :create), withdraw: %{amount_cents: 10_000})

      assert_no_emails_delivered()

      assert %{
               "errors" => %{
                 "from_user" => ["doesn't have suficient money"]
               }
             } == json_response(conn, 422)
    end

    test "renders errors when doesn't provide the withdraw amount", %{conn: conn} do
      conn = post(conn, Routes.withdraw_path(conn, :create), withdraw: @invalid_attrs)

      assert_no_emails_delivered()

      assert %{
               "errors" => %{
                 "amount_cents" => ["must be greater than 0"],
                 "postings" => [
                   %{"amount" => ["must be greater than 0"]},
                   %{"amount" => ["must be greater than 0"]}
                 ]
               }
             } == json_response(conn, 422)
    end

    test "renders errors when the provided withdraw amount is 0", %{conn: conn} do
      conn = post(conn, Routes.withdraw_path(conn, :create), withdraw: %{amount_cents: 0})

      assert_no_emails_delivered()

      assert %{
               "errors" => %{
                 "amount_cents" => ["must be greater than 0"],
                 "postings" => [
                   %{"amount" => ["must be greater than 0"]},
                   %{"amount" => ["must be greater than 0"]}
                 ]
               }
             } == json_response(conn, 422)
    end
  end
end
