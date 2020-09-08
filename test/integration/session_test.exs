defmodule BankingApi.SessionTest do
  use BankingApi.IntegrationCase

  setup do
    Hound.start_session
    user = insert(:user)

    %{user: user}
  end

  describe "login" do
    test "redirects to root path after login", %{user: user} do
      login(user)

      assert current_path() == "/"
    end
  end

  describe "logout" do
    test "returns to login page", %{user: user}  do
      login(user)

      logout = find_element(:link_text, "Logout")
      click(logout)

      assert current_path() == "/login"
    end
  end

  defp login(user) do
    navigate_to("/")

    email = find_element(:id, "user_email")
    fill_field(email, user.email)

    password = find_element(:id, "user_password")
    fill_field(password, "password")

    submit = find_element(:tag, "button")
    click(submit)
  end
end
