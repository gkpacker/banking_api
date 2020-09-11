defmodule BankingApi.Bank do
  @moduledoc """
  The Bank context.
  """

  import Ecto.Query, warn: false
  alias BankingApi.Repo

  alias BankingApi.Accounts.User
  alias BankingApi.Bank.{Account, Posting, Transaction}

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
  def list_transactions_featuring_user(%User{} = user) do
    Transaction
    |> Transaction.featuring_user(user)
    |> Repo.all()
    |> Repo.preload([:from_user, :to_user])
  end

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
          date: Date.utc_today(),
          amount_cents: initial_credit_cents,
          to_user_id: user.id,
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
        transaction = Repo.preload(transaction, :to_user)

        {:ok, %Transaction{transaction | to_user: calculate_user_balance(transaction.to_user)}}

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

  def create_transfer(%User{} = user, %User{} = to_user, attrs \\ %{}) do
    amount_cents = Map.get(attrs, "amount_cents")

    {:ok, ecto_transaction} =
      Repo.transaction(fn ->
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

  def amount_from_cents(nil), do: Decimal.round(0, 2)

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

  def transaction_report(%User{} = user) do
    [["Period", "Received", "Sent"]] ++
      report_rows_by_days(user) ++
      report_rows_by_months(user) ++
      report_rows_by_years(user) ++
      total_transactions_report_row(user)
  end

  defp report_rows_by_days(%User{} = user) do
    sent = amount_sent_by_days(user)
    received = amount_received_by_days(user)

    build_report_rows(sent, received)
  end

  defp report_rows_by_months(%User{} = user) do
    sent = amount_sent_by_months(user)
    received = amount_received_by_months(user)

    build_report_rows(sent, received)
  end

  defp report_rows_by_years(%User{} = user) do
    sent = amount_sent_by_years(user)
    received = amount_received_by_years(user)

    build_report_rows(sent, received)
  end

  defp total_transactions_report_row(%User{} = user) do
    [sent] =
      Transaction
      |> Transaction.from_user(user)
      |> Transaction.sum_amount_cents()
      |> Repo.all()

    [received] =
      Transaction
      |> Transaction.to_user(user)
      |> Transaction.sum_amount_cents()
      |> Repo.all()

    [["Total", "R$ #{amount_from_cents(received)}", "R$ #{amount_from_cents(sent)}"]]
  end

  defp build_report_rows(sent, received) do
    (Map.keys(sent) ++ Map.keys(received))
    |> Stream.uniq()
    |> Stream.map(
      &{&1, %{sent: amount_from_cents(sent[&1]), received: amount_from_cents(received[&1])}}
    )
    |> Enum.map(fn {date, amounts} ->
      [date, "R$ #{amounts[:received]}", "R$ #{amounts[:sent]}"]
    end)
  end

  defp amount_sent_by_days(%User{} = user) do
    Transaction
    |> Transaction.from_user(user)
    |> Transaction.amount_grouped_by_days()
    |> Repo.all()
    |> Map.new(fn [k, v] -> {k, v} end)
  end

  defp amount_received_by_days(%User{} = user) do
    Transaction
    |> Transaction.to_user(user)
    |> Transaction.amount_grouped_by_days()
    |> Repo.all()
    |> Map.new(fn [k, v] -> {k, v} end)
  end

  defp amount_sent_by_months(%User{} = user) do
    Transaction
    |> Transaction.from_user(user)
    |> Transaction.amount_grouped_by_months()
    |> Repo.all()
    |> Map.new(fn [k, v] -> {k, v} end)
  end

  defp amount_received_by_months(%User{} = user) do
    Transaction
    |> Transaction.to_user(user)
    |> Transaction.amount_grouped_by_months()
    |> Repo.all()
    |> Map.new(fn [k, v] -> {k, v} end)
  end

  defp amount_sent_by_years(%User{} = user) do
    Transaction
    |> Transaction.from_user(user)
    |> Transaction.amount_grouped_by_years()
    |> Repo.all()
    |> Map.new(fn [k, v] -> {k, v} end)
  end

  defp amount_received_by_years(%User{} = user) do
    Transaction
    |> Transaction.to_user(user)
    |> Transaction.amount_grouped_by_years()
    |> Repo.all()
    |> Map.new(fn [k, v] -> {k, v} end)
  end
end
