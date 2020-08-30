defmodule BankingApi.Bank.Account do
  @moduledoc """
  Represents accounts in the system which are of _asset_, _liability_, or
  _equity_ types, in accordance with the "accounting equation".
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
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
  end

  def checking_account_name, do: "Checking"
  def drawings_account_name, do: "Drawings"
  def initial_credits_account_name, do: "Initial Credits"
  def payable_account_name, do: "Accounts Payable"
  def receivable_account_name, do: "Accounts Receivable"

  def lock(query \\ Account) do
    from a in query, lock: "FOR UPDATE NOWAIT"
  end

  def assets(query \\ Account) do
    from a in query, where: a.type == ^"asset"
  end

  def liabilities(query \\ Account) do
    from a in query, where: a.type == ^"liability"
  end

  def by_name(query \\ Account, name) do
    from a in query, where: a.name == ^name
  end

  def by_user(query \\ Account, user) do
    from a in query, where: a.user_id == ^user.id
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

  def balance([]), do: Decimal.new(0)

  def balance(accounts) when is_list(accounts) do
    debit_balance = balance_debit_accounts(accounts)
    credit_balance = balance_credit_accounts(accounts)

    Decimal.sub(debit_balance, credit_balance)
  end

  defp balance_debit_accounts(accounts) do
    debit_accounts = Enum.filter(accounts, fn account -> account.type in @debit_types end)

    balance_same_type_accounts(debit_accounts)
  end

  defp balance_credit_accounts(accounts) do
    credit_accounts = Enum.filter(accounts, fn account -> account.type in @credit_types end)

    balance_same_type_accounts(credit_accounts)
  end

  defp balance_same_type_accounts(accounts) do
    Enum.reduce(accounts, Decimal.new(0), fn account, acc ->
      Decimal.add(Account.balance(account), acc)
    end)
  end
end
