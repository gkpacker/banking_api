defmodule BankingApi.BackOfficeControllerTest do
  use BankingApiWeb.ConnCase

  test "redirects to login page when not authenticated", %{conn: conn} do
    conn = get(conn, Routes.back_office_path(conn, :index))

    assert html_response(conn, 302) =~ "You are being <a href=\"/login\">redirected</a>"
  end

  describe "authenticated" do
    setup %{conn: conn} do
      user = insert(:user)

      conn =
        post(conn, Routes.session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "password"}
        })

      {:ok, conn: conn, user: user}
    end

    test "index shows user's balance", %{conn: conn, user: user} do
      conn = get(conn, Routes.back_office_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Hey, #{user.email}!"
      assert response =~ "Your balance is R$ 0.00"
    end

    test "export downloads a csv report", %{conn: conn} do
      conn = put(conn, Routes.back_office_path(conn, :export))
      response = response(conn, 200)

      assert response =~ "Period,Received,Sent\r\n"
      assert response =~ "Total,R$ 0.00,R$ 0.00\r\n"
    end
  end
end
