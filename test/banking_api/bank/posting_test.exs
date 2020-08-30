defmodule BankingApi.Bank.PostingTest do
  use BankingApi.DataCase, async: true
  alias BankingApi.Bank.Posting

  describe "Posting.changeset/2" do
    @valid_credit_params %{amount: 100, type: "credit"}
    @valid_debit_params %{amount: 100, type: "debit"}
    @invalid_type %{amount: 10, type: "invalid"}
    @invalid_amount %{amount: -1, type: "credit"}

    test "amount must be greater than or equal to 0" do
      changeset = Posting.changeset(%Posting{}, @invalid_amount)

      assert "must be greater than or equal to 0" in errors_on(changeset).amount
    end

    test "types that aren't either 'credit' nor 'debit' are invalid" do
      changeset = Posting.changeset(%Posting{}, @invalid_type)

      assert "is invalid" in errors_on(changeset).type
    end

    test "'credit' type is valid" do
      changeset = Posting.changeset(%Posting{}, @valid_credit_params)

      assert changeset.valid?
    end

    test "'debit' type is valid" do
      changeset = Posting.changeset(%Posting{}, @valid_debit_params)

      assert changeset.valid?
    end

    test "type and amount are required" do
      changeset = Posting.changeset(%Posting{}, %{})

      assert "can't be blank" in errors_on(changeset).type
      assert "can't be blank" in errors_on(changeset).amount
    end
  end

  describe "Posting.for_account/2" do
    test "returns only postings for given account" do
      account = insert(:debit_account)
      posting = insert(:debit, account: account)
      another_account_posting = insert(:debit)

      [first_posting | tail] =
        Posting
        |> Posting.for_account(account)
        |> Repo.all()
        |> Repo.preload([:account, :transaction])

      assert posting.id == first_posting.id
      refute another_account_posting in tail
    end
  end

  describe "Posting.sum_credits/1" do
    test "returns the sum of all 'credit' postings in a query" do
      insert(:credit, amount: 1000)
      insert(:credit, amount: 1000)
      insert(:debit, amount: 100)

      [sum] =
        Posting
        |> Posting.sum_credits()
        |> Repo.all()

      assert sum == Decimal.new(2000)
    end
  end

  describe "Posting.sum_debits/1" do
    test "returns the sum of all 'debit' postings in a query" do
      insert(:credit, amount: 1000)
      insert(:debit, amount: 500)
      insert(:debit, amount: 600)

      [sum] =
        Posting
        |> Posting.sum_debits()
        |> Repo.all()

      assert sum == Decimal.new(1100)
    end
  end
end
