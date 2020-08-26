defmodule BankingApi.Bank.Account do
  @moduledoc """
  Represents accounts in the system which are of _asset_, _liability_, or
  _equity_ types, in accordance with the "accounting equation".
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias BankingApi.Accounts.User

  @debit_types ~w(asset)
  @credit_types ~w(liability equity)

  schema "accounts" do
    field :contra, :boolean, default: false
    field :name, :string
    field :type, :string
    belongs_to :user, User

    timestamps()
  end

  @doc """
  Creates an Account requiring `name` and `type` attributes.

  Validates `type` attribute inclusion in `asset`, `liability` and `equity`.
  """
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :type, :contra, :user_id])
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, @credit_types ++ @debit_types)
    |> assoc_constraint(:user)
  end
end
