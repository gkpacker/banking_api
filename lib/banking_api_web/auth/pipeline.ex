defmodule BankingApiWeb.Auth.Pipeline do
  @moduledoc """
  Provides a pipeline for authenticated routes
  """

  use Guardian.Plug.Pipeline,
    otp_app: :banking_api,
    module: BankingApiWeb.Auth.Guardian,
    error_handler: BankingApiWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.LoadResource, allow_blank: true
end
