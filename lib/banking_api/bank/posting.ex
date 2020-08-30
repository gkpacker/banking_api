defmodule BankingApi.Bank.Posting do
  @moduledoc """
  The Posting module represent a credit or a debit posting to an account.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
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

  @doc """
  Returns all postings for an account
  """
  def for_account(query, account) do
    from p in query,
      join: a in assoc(p, :account),
      where: a.id == ^account.id
  end

  @doc """
  Sum all credit postings for given query
  """
  def sum_credits(query) do
    from p in query,
      where: p.type == ^"credit",
      select: sum(p.amount)
  end

  @doc """
  Sum all debit postings for given query
  """
  def sum_debits(query) do
    from p in query,
      where: p.type == ^"debit",
      select: sum(p.amount)
  end
end
