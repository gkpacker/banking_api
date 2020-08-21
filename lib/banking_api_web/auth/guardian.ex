defmodule BankingApiWeb.Auth.Guardian do
  use Guardian, otp_app: :banking_api

  alias BankingApi.Accounts

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Accounts.get_user!(id)
    {:ok,  resource}
  end

  def authenticate(email, password) do
    email
    |> Accounts.get_by_email
    |> authenticate_user(password)
  end

  defp authenticate_user({:ok, user}, password) do
    case validate_password(password, user.encrypted_password) do
      true -> create_token(user)
      false -> {:error, :unauthorized}
    end
  end
  defp authenticate_user({:error, :not_found}, _password),
    do: {:error, :unauthorized}

  defp validate_password(password, encrypted_password) do
    Bcrypt.verify_pass(password, encrypted_password)
  end

  defp create_token(user) do
    {:ok, token, _claims} = encode_and_sign(user)
    {:ok, user, token}
  end
end
