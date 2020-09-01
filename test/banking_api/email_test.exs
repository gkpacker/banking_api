defmodule BankingApi.EmailTest do
  use BankingApi.DataCase, async: true
  alias BankingApi.Email

  test "user_withdraw_html_email/3" do
    user_email = "user@email.com"
    balance = Decimal.new(80_000)
    withdraw_amount = 20_000
    email = Email.user_withdraw_html_email(user_email, balance, withdraw_amount)

    assert email.to == user_email
    assert email.from == "banking.api@bank.com"
    assert email.html_body =~ "Hey, user@email.com!"
    assert email.html_body =~ "<p>Your R$ 200.00 withdraw request was successfully performed.<p>"
    assert email.html_body =~ "<p>Your balance is R$ 800.00</p>"
    assert email.text_body =~ "Hey, user@email.com!"
    assert email.text_body =~ "Your R$ 200.00 withdraw request was successfully performed."
    assert email.text_body =~ "Your balance is R$ 800.00"
  end
end
