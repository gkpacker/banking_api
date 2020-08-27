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
end
