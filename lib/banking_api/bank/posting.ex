defmodule BankingApi.Bank.Posting do
  @moduledoc """
  The Posting module represent a credit or a debit posting to an account.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias BankingApi.Bank.{Account, Transaction}

  schema "postings" do
    field :amount, :decimal
    field :type, :string

    belongs_to :transaction, Transaction
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(posting, attrs) do
    posting
    |> cast(attrs, [:type, :amount, :account_id, :transaction_id])
    |> validate_required([:type, :amount])
    |> validate_inclusion(:type, ["credit", "debit"])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> assoc_constraint(:account)
    |> assoc_constraint(:transaction)
  end
end
