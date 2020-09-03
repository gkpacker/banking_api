defmodule BankingApi.Bank.Transaction do
  @moduledoc """
  The Transaction module keeps track of all Postings
  in a transaction.

  Credits and debits must balance in order to the Transaction
  be valid.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias BankingApi.Accounts
  alias BankingApi.Accounts.User
  alias BankingApi.Bank
  alias BankingApi.Bank.Posting

  @fields [:name, :date, :amount_cents, :type, :from_user_id, :to_user_id]

  @transfer "transfer"
  @deposit "deposit"
  @withdraw "withdraw"
  @valid_types [@transfer, @deposit, @withdraw]

  schema "transactions" do
    field :date, :date
    field :name, :string
    field :type, :string
    field :amount_cents, :decimal

    belongs_to :from_user, User
    belongs_to :to_user, User
    has_many :postings, Posting

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @fields)
    |> validate_required([:name, :date, :amount_cents, :type])
    |> validate_number(:amount_cents, greater_than: 0)
    |> validate_inclusion(:type, @valid_types)
    |> assoc_constraint(:from_user, required: true)
    |> assoc_constraint(:to_user)
    |> validate_from_user_balance
    |> validate_transaction_target
    |> cast_assoc(:postings, required: true)
    |> validate_postings_balance
  end

  defp validate_transaction_target(
         %Ecto.Changeset{
           valid?: true,
           changes: %{type: @transfer, from_user_id: from_user_id, to_user_id: to_user_id}
         } = changeset
       )
       when from_user_id == to_user_id,
       do: add_error(changeset, :from_user, "can't transfer to himself")

  defp validate_transaction_target(changeset), do: changeset

  defp validate_from_user_balance(
         %Ecto.Changeset{
           valid?: true,
           changes: %{type: type, amount_cents: amount_cents, from_user_id: from_user_id}
         } = changeset
       )
       when type in [@withdraw, @transfer] do
    %User{balance: balance} =
      Accounts.get_user!(from_user_id)
      |> Bank.calculate_user_balance()

    next_balance = Decimal.sub(balance, Decimal.new(amount_cents))

    if Decimal.negative?(next_balance) do
      add_error(changeset, :from_user, "doesn't have suficient money")
    else
      changeset
    end
  end

  defp validate_from_user_balance(changeset), do: changeset

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
