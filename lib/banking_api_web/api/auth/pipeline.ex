defmodule BankingApiWeb.Api.Auth.Pipeline do
  @moduledoc """
  Provides a pipeline for authenticated routes
  """

  use Guardian.Plug.Pipeline,
    otp_app: :banking_api,
    module: BankingApiWeb.Auth.Guardian,
    error_handler: BankingApiWeb.Api.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
