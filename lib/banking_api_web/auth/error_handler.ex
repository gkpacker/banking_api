defmodule BankingApiWeb.Auth.ErrorHandler do
  @moduledoc """
  Handle authentication related errors
  """

  import Plug.Conn
  use BankingApiWeb, :controller

  def auth_error(conn, {type, _reason}, _opts) do
    body = to_string(type)

    conn
    |> put_flash(:error, body)
    |> redirect(to: "/login")
  end
end
