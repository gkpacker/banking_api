defmodule BankingApi.Bank.Transaction do
  @moduledoc """
  The Transaction module keeps track of all Postings
  in a transaction.

  Credits and debits must balance in order to the Transaction
  be valid.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias BankingApi.Bank.Posting

  schema "transactions" do
    field :date, :date
    field :name, :string

    has_many :postings, Posting

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:name, :date])
    |> validate_required([:name, :date])
    |> cast_assoc(:postings, required: true)
    |> validate_postings_balance
  end

  defp validate_postings_balance(%Ecto.Changeset{valid?: true} = changeset) do
    postings = Ecto.Changeset.get_field(changeset, :postings)
    mapped_postings = Enum.group_by(postings, fn p -> p.type end)

    credit_sum = sum_postings(mapped_postings["credit"])
    debit_sum = sum_postings(mapped_postings["debit"])

    if credit_sum == debit_sum do
      changeset
    else
      add_error(changeset, :postings, "credits and debits must balance")
    end
  end

  defp validate_postings_balance(changeset), do: changeset

  defp sum_postings(postings) do
    Enum.reduce(postings, Decimal.new(0), fn p, acc -> Decimal.add(p.amount, acc) end)
  end
end
