defmodule BankingApi.SessionControllerTest do
  use BankingApiWeb.ConnCase

  test "login route does not requires authentication", %{conn: conn} do
    conn = get(conn, Routes.session_path(conn, :new))

    assert html_response(conn, 200) =~ "Login"
    assert html_response(conn, 200) =~ "Email"
    assert html_response(conn, 200) =~ "Password"
  end

  test "redirects to root path after login", %{conn: conn} do
    user = insert(:user)

    attrs = %{
      "user" => %{
        "email" => user.email,
        "password" => "password"
      }
    }

    conn = post(conn, Routes.session_path(conn, :create), attrs)

    assert Guardian.Plug.authenticated?(conn)
    assert html_response(conn, 302) =~ "You are being <a href=\"/\">redirected</a>."
  end

  describe "authenticated" do
    setup %{conn: conn} do
      user = insert(:user)

      attrs = %{
        "user" => %{
          "email" => user.email,
          "password" => "password"
        }
      }

      conn = post(conn, Routes.session_path(conn, :create), attrs)

      %{conn: conn}
    end

    test "logout redirects to login after unauthenticating user", %{conn: conn} do
      conn = delete(conn, "/logout")

      refute Guardian.Plug.authenticated?(conn)
      assert html_response(conn, 302) =~ "You are being <a href=\"/login\">redirected</a>."
    end
  end
end
