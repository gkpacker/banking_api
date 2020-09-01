defmodule BankingApi.Email do
  @moduledoc false

  use Bamboo.Phoenix, view: BankingApiWeb.EmailView
  alias BankingApi.Bank

  def user_withdraw_text_email(email, balance, amount) do
    new_email()
    |> to(email)
    |> from("banking.api@bank.com")
    |> subject("Withdraw performed successfuly!")
    |> put_text_layout({BankingApiWeb.LayoutView, "email.text"})
    |> render("user_withdraw.text", email: email, balance: balance, amount: amount)
  end

  def user_withdraw_html_email(email, balance_cents, amount_cents) do
    balance = Bank.amount_from_cents(balance_cents)
    amount = Bank.amount_from_cents(amount_cents)

    user_withdraw_text_email(email, balance, amount)
    |> put_html_layout({BankingApiWeb.LayoutView, "email.html"})
    |> render("user_withdraw.html", email: email, balance: balance, amount: amount)
  end
end
