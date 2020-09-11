defmodule BankingApi.Bank.TransactionTest do
  use BankingApi.DataCase, async: true
  alias BankingApi.Bank.Transaction

  describe "Transaction.changeset/2" do
    @without_postings %{date: ~D[2000-03-10]}
    @invalid_attrs %{date: nil}

    test "isn't valid without postings" do
      changeset = Transaction.changeset(%Transaction{}, @without_postings)

      assert "can't be blank" in errors_on(changeset).postings
    end

    test "isn't valid without type and date" do
      changeset = Transaction.changeset(%Transaction{}, @invalid_attrs)

      assert "can't be blank" in errors_on(changeset).type
      assert "can't be blank" in errors_on(changeset).date
    end

    test "is valid when credits and debits postings balance" do
      user = insert(:user)
      insert(:initial_accounts, user: user)
      credit_account = insert(:credit_account, user: user)
      debit_account = insert(:debit_account, user: user)
      date = Date.utc_today()

      params = %{
        date: date,
        amount_cents: 1000,
        type: "transfer",
        postings: [
          %{type: "debit", amount: 1000, account_id: credit_account.id},
          %{type: "credit", amount: 1000, account_id: debit_account.id}
        ]
      }

      changeset = Transaction.changeset(%Transaction{}, params)

      assert changeset.valid?
    end

    test "is valid with many postings when credits and debits balance" do
      credit_account = insert(:credit_account)
      debit_account = insert(:debit_account)
      date = Date.utc_today()

      params = %{
        date: date,
        amount_cents: 1000,
        type: "transfer",
        postings: [
          %{type: "debit", amount: 500, account_id: credit_account.id},
          %{type: "debit", amount: 500, account_id: credit_account.id},
          %{type: "credit", amount: 600, account_id: debit_account.id},
          %{type: "credit", amount: 400, account_id: debit_account.id}
        ]
      }

      changeset = Transaction.changeset(%Transaction{}, params)

      assert changeset.valid?
    end

    test "isn't valid when credits and debits doesn't balance" do
      user = insert(:user)
      insert(:initial_accounts, user: user)
      credit_account = insert(:credit_account, user: user)
      debit_account = insert(:debit_account, user: user)
      date = Date.utc_today()

      params = %{
        date: date,
        type: "transfer",
        amount_cents: 1000,
        from_user_id: user.id,
        postings: [
          %{type: "debit", amount: 1000, account_id: credit_account.id},
          %{type: "credit", amount: 1100, account_id: debit_account.id}
        ]
      }

      changeset = Transaction.changeset(%Transaction{}, params)

      assert "credits and debits must balance" in errors_on(changeset).postings
    end
  end

  describe "withdraw transaction" do
    @withdraw "withdraw"
    @valid_withdraw_attrs %{
      type: @withdraw,
      date: ~D[2000-03-10],
      amount_cents: 50_000,
      from_user_id: 1,
      postings: []
    }

    test "it's valid when user accounts balance" do
      user = insert(:user)
      insert(:initial_accounts, user: user)

      changeset =
        Transaction.changeset(
          %Transaction{},
          %{
            @valid_withdraw_attrs
            | from_user_id: user.id,
              postings: [
                %{type: "debit", amount: 1000, account_id: insert(:credit_account).id},
                %{type: "credit", amount: 1000, account_id: insert(:debit_account).id}
              ]
          }
        )

      assert changeset.valid?
    end

    test "it isn's valid when user doesn't have suficient cash" do
      user = insert(:user)
      insert(:initial_accounts, user: user, user_balance: 30_000)

      changeset =
        Transaction.changeset(
          %Transaction{},
          %{
            @valid_withdraw_attrs
            | from_user_id: user.id,
              postings: [
                %{type: "debit", amount: 30_000, account_id: insert(:credit_account).id},
                %{type: "credit", amount: 30_000, account_id: insert(:debit_account).id}
              ]
          }
        )

      refute changeset.valid?
      assert "doesn't have suficient money" in errors_on(changeset).from_user
    end

    test "creates a withdraw transaction when it's valid" do
      user = insert(:user)
      insert(:initial_accounts, user: user)
      amount_cents = 50_000

      changeset =
        Transaction.changeset(%Transaction{}, %{
          @valid_withdraw_attrs
          | amount_cents: amount_cents,
            from_user_id: user.id,
            postings: [
              %{type: "debit", amount: amount_cents, account_id: insert(:credit_account).id},
              %{type: "credit", amount: amount_cents, account_id: insert(:debit_account).id}
            ]
        })

      assert changeset.valid?
    end
  end

  test "Transaction.amount_grouped_by_days/1" do
    today = Date.utc_today()
    yesterday = Date.add(today, -1)
    insert(:transaction, date: today)
    insert(:transaction, date: yesterday)
    insert(:transaction, date: yesterday)

    result =
      Transaction
      |> Transaction.amount_grouped_by_days()
      |> BankingApi.Repo.all()

    {:ok, today_date} = Calendar.Strftime.strftime(today, "%d/%m/%Y")
    {:ok, yesterday_date} = Calendar.Strftime.strftime(yesterday, "%d/%m/%Y")

    assert [
             [today_date, Decimal.new(1000)],
             [yesterday_date, Decimal.new(2000)]
           ] == result
  end

  test "Transaction.amount_grouped_by_months/1" do
    today = Date.utc_today()
    last_month_date = Date.add(today, -31)
    insert(:transaction, date: today)
    insert(:transaction, date: today)
    insert(:transaction, date: last_month_date)

    result =
      Transaction
      |> Transaction.amount_grouped_by_months()
      |> BankingApi.Repo.all()

    {:ok, mon_yy} = Calendar.Strftime.strftime(today, "%m/%Y")
    {:ok, last_mon_yy} = Calendar.Strftime.strftime(last_month_date, "%m/%Y")

    assert [
             [mon_yy, Decimal.new(2000)],
             [last_mon_yy, Decimal.new(1000)]
           ] == result
  end

  test "Transaction.from_user/2" do
    user = insert(:user)
    transaction_from_user = insert(:transaction, from_user: user)
    insert(:transaction, to_user: user)

    [transaction] =
      Transaction
      |> Transaction.from_user(user)
      |> BankingApi.Repo.all()

    assert transaction.id == transaction_from_user.id
  end

  test "Transaction.to_user/2" do
    user = insert(:user)
    insert(:transaction, from_user: user)
    transaction_to_user = insert(:transaction, to_user: user)

    [transaction] =
      Transaction
      |> Transaction.to_user(user)
      |> BankingApi.Repo.all()

    assert transaction.id == transaction_to_user.id
  end
end
