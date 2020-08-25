defmodule BankingApi.Accounts.User do
  @moduledoc """
  Represents real users throughout the system
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias BankingApi.Bank.Account

  schema "users" do
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true
    has_many :accounts, Account, on_delete: :nilify_all

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> put_hashed_password()
  end

  defp put_hashed_password(
    %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
  ) do
    put_change(changeset, :encrypted_password, Bcrypt.hash_pwd_salt(password))
  end
  defp put_hashed_password(changeset), do: changeset
end
