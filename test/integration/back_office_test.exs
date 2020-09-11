defmodule BankingApi.BackOfficeTest do
  use BankingApi.IntegrationCase

  setup do
    Hound.start_session()
    :ok
  end

  describe "when not logged in" do
    test "redirects to login page" do
      navigate_to("/")

      assert current_path() == "/login"
    end
  end

  describe "when logged in" do
    setup do
      user = insert(:user)
      transaction = insert(:deposit, user: user)

      navigate_to("/")

      email = find_element(:id, "user_email")
      fill_field(email, user.email)

      password = find_element(:id, "user_password")
      fill_field(password, "password")

      submit = find_element(:tag, "button")
      click(submit)

      %{user: user, transaction: transaction}
    end

    test "list user transactions", %{transaction: transaction} do
      table = find_element(:tag, "table")
      items = transaction_table_items()

      assert page_source() =~ "Your balance is R$ 1000.00"
      assert length(items) == 2
      assert transaction_on_the_table?(transaction, table)
    end

    test "has an export link" do
      assert find_element(:link_text, "Export")
    end

    defp transaction_on_the_table?(transaction, table) do
      table
      |> visible_text
      |> String.contains?(to_string(transaction.id))
    end

    defp transaction_table_items do
      find_element(:tag, "tbody")
      |> find_all_within_element(:tag, "tr")
    end
  end
end
