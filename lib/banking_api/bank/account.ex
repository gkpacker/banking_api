defmodule BankingApi.Bank.Account do
  @moduledoc """
  Represents accounts in the system which are of _asset_, _liability_, or
  _equity_ types, in accordance with the "accounting equation".
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias BankingApi.Accounts.User
  alias BankingApi.Bank
  alias BankingApi.Bank.{Account, Posting}

  @debit_types ~w(asset)
  @credit_types ~w(liability equity)

  schema "accounts" do
    field :contra, :boolean, default: false
    field :name, :string
    field :type, :string

    belongs_to :user, User
    has_many :postings, Posting, on_delete: :delete_all

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
    |> cast_assoc(:postings)
  end

  def balance(%Account{type: type, contra: false} = account) when type in @debit_types do
    debits = Bank.sum_account_debits(account)
    credits = Bank.sum_account_credits(account)

    Decimal.sub(debits, credits)
  end

  def balance(%Account{type: type, contra: true} = account) when type in @debit_types do
    credits = Bank.sum_account_credits(account)
    debits = Bank.sum_account_debits(account)

    Decimal.sub(credits, debits)
  end

  def balance(%Account{contra: false} = account) do
    credits = Bank.sum_account_credits(account)
    debits = Bank.sum_account_debits(account)

    Decimal.sub(credits, debits)
  end

  def balance(%Account{contra: true} = account) do
    debits = Bank.sum_account_debits(account)
    credits = Bank.sum_account_credits(account)

    Decimal.sub(debits, credits)
  end
end
