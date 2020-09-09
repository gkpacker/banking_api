defmodule BankingApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Repo

  alias BankingApi.Accounts.User

  @doc """
  Gets a single user with its accounts.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{
        accounts: [%Account{}, %Account{}]
      }

      iex> get_user(456)
      nil

  """
  def get_user(id) do
    User
    |> Repo.get(id)
    |> Repo.preload(:accounts)
  end

  @doc """
  Gets a single user by email.

  Returns `{:error, :not_found}` if there's no User with given email.

  ## Examples

      iex> get_user_by_email(123)
      {:ok, %User{}}

      iex> get_user_by_email(456)
      {:error, :not_found}

  """
  def get_user_by_email(email) do
    case Repo.get_by(User, email: email) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, Repo.preload(user, :accounts)}
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  ## Examples
      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
