defmodule BankingApi.BankTest do
  use BankingApi.DataCase

  alias BankingApi.Bank

  describe "accounts" do
    alias BankingApi.Bank.Account

    @valid_attrs %{contra: false, name: "Cash", type: "asset", user_id: 1}
    @update_attrs %{contra: true, name: "Drawing", type: "asset"}
    @invalid_attrs %{contra: nil, name: nil, type: nil}
    @invalid_type_attrs %{contra: false, name: "Cash", type: "invalid"}

    setup %{} do
      user = insert(:user)

      {:ok, user: user, valid_attrs: %{@valid_attrs | user_id: user.id}}
    end

    test "list_accounts/0 returns all accounts" do
      account = insert(:account)
      assert Bank.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = insert(:account)
      assert Bank.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(valid_attrs)
      assert account.contra == false
      assert account.name == "Cash"
      assert account.type == "asset"
    end

    test "create_account/1 with asset type is valid", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(%{valid_attrs | type: "asset"})
      assert account.type == "asset"
    end

    test "create_account/1 with liability type is valid", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(%{valid_attrs | type: "liability"})
      assert account.type == "liability"
    end

    test "create_account/1 with equity type is valid", %{valid_attrs: valid_attrs} do
      assert {:ok, %Account{} = account} = Bank.create_account(%{valid_attrs | type: "equity"})
      assert account.type == "equity"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_account(@invalid_attrs)
    end

    test "create_account/1 with invalid type returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_account(@invalid_type_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = insert(:account)
      assert {:ok, %Account{} = account} = Bank.update_account(account, @update_attrs)
      assert account.contra == true
      assert account.name == "Drawing"
      assert account.type == "asset"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = insert(:account)
      assert {:error, %Ecto.Changeset{}} = Bank.update_account(account, @invalid_attrs)
      assert account == Bank.get_account!(account.id)
    end

    test "update_account/2 with invalid type returns error changeset" do
      account = insert(:account)
      assert {:error, %Ecto.Changeset{}} = Bank.update_account(account, @invalid_type_attrs)
      assert account == Bank.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = insert(:account)
      assert {:ok, %Account{}} = Bank.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Bank.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = insert(:account)
      assert %Ecto.Changeset{} = Bank.change_account(account)
    end
  end
end
