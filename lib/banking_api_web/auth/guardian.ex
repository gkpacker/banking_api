defmodule BankingApiWeb.Auth.Guardian do
  @moduledoc """
  Provides auth operations for users
  """
  use Guardian, otp_app: :banking_api

  alias BankingApi.Accounts

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Accounts.get_user(id)

    {:ok, resource}
  end

  @doc """
  Authenticates with given `email` and `password`

  Returns `{:ok, %User{}, "very_big_token"}`.

  Returns `{:error, :unauthorized}` if there's no User with given email.

  Returns `{:error, :unauthorized}` if given credentials are invalid.

  ## Examples

      iex> BankingApiWeb.Auth.Guardian.authenticate("user@email.com", "123123")
      {:ok, %User{}, "very_big_token"}

      iex> BankingApiWeb.Auth.Guardian.authenticate("not@found.com", "123123")
      {:error, :unauthorized}

      iex> BankingApiWeb.Auth.Guardian.authenticate("user@email.com", "wrong")
      {:error, :unauthorized}
  """
  def authenticate(email, password) do
    email
    |> Accounts.get_user_by_email()
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
