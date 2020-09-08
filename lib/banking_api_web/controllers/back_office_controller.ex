defmodule BankingApiWeb.BackOfficeController do
  use BankingApiWeb, :controller

  alias BankingApi.Bank
  alias BankingApiWeb.Auth.Guardian

  action_fallback BankingApiWeb.FallbackController

  def index(conn, _params) do
    user =
      Guardian.Plug.current_resource(conn)
      |> Bank.calculate_user_balance()

    transactions = Bank.list_transactions_featuring_user(user)

    render(conn, "index.html", user: user, transactions: transactions)
  end

  def export(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    report =
      Bank.transaction_report(user)
      |> CSV.encode()
      |> Enum.to_list()
      |> to_string

    send_download(
      conn,
      {:binary, report},
      content_type: "application/csv",
      filename: "report.csv"
    )
  end
end
