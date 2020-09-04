defmodule BankingApi.Bank do
  @moduledoc """
  The Bank context.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Repo

  alias BankingApi.Accounts
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

      iex> get_and_lock_account("Checking")
      %Account{name: "Checking"}

  """
  def get_and_lock_account(attrs \\ %{}) do
    case get_or_create_account(attrs) do
      {:ok, account} -> Account.lock(account)
      error -> error
    end
  end

  def get_or_create_account(attrs \\ %{}) do
    case Repo.get_by(Account, attrs) do
      nil ->
        {:ok, account} = create_account(attrs)
        account

      account ->
        account
    end
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

      iex> calculate_user_balance(user)
      %User{balance: #Decimal<100_000>}

  """
  def calculate_user_balance(%User{} = user) do
    user_accounts = Account.by_user(Account, user)
    user_assets = asset_accounts(user_accounts)
    user_liabilities = liability_accounts(user_accounts)

    %User{user | balance: Account.balance(user_assets ++ user_liabilities)}
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
    {:ok, transaction_changeset} =
      Repo.transaction(fn ->
        checking_account =
          get_and_lock_account(%{
            user_id: user.id,
            name: Account.checking_account_name(),
            type: "asset"
          })

        initial_credit_account =
          get_and_lock_account(%{
            user_id: user.id,
            name: Account.initial_credits_account_name(),
            type: "equity"
          })

        initial_credit_cents = amount_to_cents(1000)

        create_transaction(%{
          name: "Initial Credit",
          date: Date.utc_today(),
          amount_cents: initial_credit_cents,
          from_user_id: user.id,
          type: "deposit",
          postings: [
            %{
              type: "credit",
              amount: initial_credit_cents,
              account_id: initial_credit_account.id
            },
            %{type: "debit", amount: initial_credit_cents, account_id: checking_account.id}
          ]
        })
      end)

    case transaction_changeset do
      {:ok, transaction} ->
        transaction = Repo.preload(transaction, :from_user)

        {:ok,
         %Transaction{transaction | from_user: calculate_user_balance(transaction.from_user)}}

      changeset ->
        changeset
    end
  end

  @doc """
  Creates a withdraw.

  Returns the user with its current balance.

  ## Examples

      iex> create_withdraw(%{field: value})
      {:ok, %Transaction{user: %User{balance: #Decimal<100_000>}}}

      iex> create_withdraw(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_withdraw(%User{} = user, attrs \\ %{}) do
    amount_cents = Map.get(attrs, "amount_cents")

    {:ok, transaction_changeset} =
      Repo.transaction(fn ->
        checking_account =
          get_and_lock_account(%{
            user_id: user.id,
            name: Account.checking_account_name(),
            type: "asset"
          })

        drawings_account =
          get_and_lock_account(%{
            user_id: user.id,
            name: Account.drawings_account_name(),
            type: "equity",
            contra: true
          })

        create_transaction(%{
          name: "Withdraw",
          date: Date.utc_today(),
          amount_cents: amount_cents,
          from_user_id: user.id,
          type: "withdraw",
          postings: [
            %{type: "credit", amount: amount_cents, account_id: checking_account.id},
            %{type: "debit", amount: amount_cents, account_id: drawings_account.id}
          ]
        })
      end)

    case transaction_changeset do
      {:ok, transaction} ->
        transaction = Repo.preload(transaction, :from_user)

        {:ok,
         %Transaction{transaction | from_user: calculate_user_balance(transaction.from_user)}}

      changeset ->
        changeset
    end
  end

  def create_transfer(%User{} = user, attrs \\ %{}) do
    amount_cents = Map.get(attrs, "amount_cents")
    to_user_email = Map.get(attrs, "to")

    {:ok, ecto_transaction} =
      Repo.transaction(fn ->
        to_user = Accounts.get_user_by_email!(to_user_email)

        from_user_checking_account =
          get_and_lock_account(%{
            user_id: user.id,
            name: Account.checking_account_name(),
            type: "asset"
          })

        to_user_checking_account =
          get_and_lock_account(%{
            user_id: to_user.id,
            name: Account.checking_account_name(),
            type: "asset"
          })

        create_transaction(%{
          name: "Transfer",
          date: Date.utc_today(),
          amount_cents: amount_cents,
          from_user_id: user.id,
          to_user_id: to_user.id,
          type: "transfer",
          postings: [
            %{type: "credit", account_id: from_user_checking_account.id, amount: amount_cents},
            %{type: "debit", account_id: to_user_checking_account.id, amount: amount_cents}
          ]
        })
      end)

    case ecto_transaction do
      {:ok, transaction} ->
        transaction = Repo.preload(transaction, :from_user)

        {:ok, %Transaction{transaction | from_user: calculate_user_balance(user)}}

      changeset ->
        changeset
    end
  end

  @doc """
  Returns an amount from cents with 2 digits precision

  ## Example

      iex> amount_from_cents(100_000)
      #Decimal<1000.00>

  """
  def amount_from_cents(amount_cents) do
    amount_cents
    |> Decimal.div(100)
    |> Decimal.round(2)
  end

  @doc """
  Returns an amount in cents

  ## Example

      iex> amount_to_cents(1000)
      #Decimal<100_000>

  """
  def amount_to_cents(amount), do: Decimal.new(amount * 100)
end
