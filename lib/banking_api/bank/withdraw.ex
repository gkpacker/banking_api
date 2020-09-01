defmodule BankingApi.Bank.Withdraw do
  @moduledoc """
  The Withdraw module holds the user that requested the withdraw
  and a transaction that credits the user's checking account and
  debits its contra equity drawings account.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias BankingApi.Accounts
  alias BankingApi.Accounts.User
  alias BankingApi.Bank
  alias BankingApi.Bank.{Account, Transaction}

  schema "withdraws" do
    field :amount_cents, :decimal

    belongs_to :user, User
    belongs_to :transaction, Transaction

    timestamps()
  end

  @doc false
  def changeset(withdraw, attrs) do
    withdraw
    |> cast(attrs, [:amount_cents, :user_id])
    |> validate_required([:amount_cents])
    |> validate_number(:amount_cents, greater_than: 0)
    |> assoc_constraint(:user, required: true)
    |> validate_user_balance
    |> build_withdraw_transaction
    |> cast_assoc(:transaction)
  end

  defp validate_user_balance(
         %Ecto.Changeset{
           valid?: true,
           changes: %{amount_cents: amount_cents, user_id: user_id}
         } = changeset
       ) do
    %User{balance: balance} =
      Accounts.get_user!(user_id)
      |> Bank.calculate_user_balance()

    next_balance = Decimal.sub(balance, Decimal.new(amount_cents))

    if Decimal.negative?(next_balance) do
      add_error(changeset, :user, "doesn't have suficient money")
    else
      changeset
    end
  end

  defp validate_user_balance(changeset), do: changeset

  defp build_withdraw_transaction(
         %Ecto.Changeset{
           valid?: true,
           changes: %{amount_cents: amount_cents, user_id: user_id}
         } = changeset
       ) do
    user = Accounts.get_user!(user_id)

    checking_account =
      Bank.get_and_lock_user_account_by_name!(user, Account.checking_account_name())

    drawings_account =
      Bank.get_and_lock_user_account_by_name!(user, Account.drawings_account_name())

    change(
      changeset,
      transaction: %{
        name: "Withdraw",
        date: Date.utc_today(),
        postings: [
          %{type: "credit", amount: amount_cents, account_id: checking_account.id},
          %{type: "debit", amount: amount_cents, account_id: drawings_account.id}
        ]
      }
    )
  end

  defp build_withdraw_transaction(changeset), do: changeset
end
