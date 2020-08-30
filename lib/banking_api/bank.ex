defmodule BankingApi.Bank do
  @moduledoc """
  The Bank context.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Repo

  alias BankingApi.Accounts.User
  alias BankingApi.Bank.{Account, Posting, Transaction}

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Gets an user account by name and lock it.

  ## Examples

      iex> get_and_lock_user_account_by_name!("Checking")
      %Account{name: "Checking"}

  """
  def get_and_lock_user_account_by_name!(user, account_name) do
    Account
    |> Account.by_user(user)
    |> Account.by_name(account_name)
    |> Account.lock()
    |> Repo.one()
  end

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions do
    Repo.all(Transaction)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(attrs \\ %{}) do
    changeset =
      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Repo.insert()

    case changeset do
      {:ok, transaction} ->
        {:ok, Repo.preload(transaction, postings: :account)}

      changeset ->
        changeset
    end
  end

  @doc """
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  @doc """
  Returns the list of postings.

  ## Examples

      iex> list_postings()
      [%Posting{}, ...]

  """
  def list_postings do
    Posting
    |> Repo.all()
    |> Repo.preload([:account, :transaction])
  end

  @doc """
  Gets a single posting.

  Raises `Ecto.NoResultsError` if the Posting does not exist.

  ## Examples

      iex> get_posting!(123)
      %Posting{}

      iex> get_posting!(456)
      ** (Ecto.NoResultsError)

  """
  def get_posting!(id) do
    Posting
    |> Repo.get!(id)
    |> Repo.preload([:account, :transaction])
  end

  @doc """
  Sum all credit postings for given account

  ## Examples

      iex> sum_account_credits(account)
      #Decimal<10000>

      iex> sum_account_credits(account_without_postings)
      #Decimal<0>

  """
  def sum_account_credits(%Account{} = account) do
    [sum] =
      Posting
      |> Posting.for_account(account)
      |> Posting.sum_credits()
      |> Repo.all()

    if sum do
      sum
    else
      Decimal.new(0)
    end
  end

  @doc """
  Sum all debit postings for given account

  ## Examples

      iex> sum_account_debits(account)
      #Decimal<10000>

      iex> sum_account_debits(account_without_postings)
      #Decimal<0>

  """
  def sum_account_debits(%Account{} = account) do
    [sum] =
      Posting
      |> Posting.for_account(account)
      |> Posting.sum_debits()
      |> Repo.all()

    if sum do
      sum
    else
      Decimal.new(0)
    end
  end

  @doc """
  Returns user with its balance, which is calculated by
  subtracting his Liabilities from his Assets.

  [Net worth](https://en.wikipedia.org/wiki/Net_worth#Individuals)

  ## Examples

      iex> user_net_worth(user)
      %User{balance: #Decimal<100_000>}

  """
  def user_net_worth(%User{} = user) do
    user_accounts = Account.by_user(Account, user)
    user_assets = asset_accounts(user_accounts)
    user_liabilities = liability_accounts(user_accounts)

    %User{balance: Account.balance(user_assets ++ user_liabilities)}
  end

  @doc """
  Filters accounts with "asset" type.
  """
  def asset_accounts(accounts) do
    accounts
    |> Account.assets()
    |> Repo.all()
    |> Repo.preload(:postings)
  end

  @doc """
  Filters accounts with "liability" type.
  """
  def liability_accounts(accounts) do
    accounts
    |> Account.liabilities()
    |> Repo.all()
    |> Repo.preload(:postings)
  end

  @doc """
  Gives an user its initial credits (R$ 1000,00)

  ## Examples

      iex> give_initial_credits_to_user(user)
      %User{balance: 100_000}

  """
  def give_initial_credits_to_user(%User{} = user) do
    Repo.transaction(fn ->
      checking_account = get_and_lock_user_account_by_name!(user, Account.checking_account_name())

      initial_credit_account =
        get_and_lock_user_account_by_name!(user, Account.initial_credits_account_name())

      initial_credit_cents = 1000 * 100

      create_transaction(%{
        name: "Initial Credit",
        date: Date.utc_today(),
        postings: [
          %{type: "credit", amount: initial_credit_cents, account_id: initial_credit_account.id},
          %{type: "debit", amount: initial_credit_cents, account_id: checking_account.id}
        ]
      })
    end)

    {:ok, user_net_worth(user)}
  end
end
