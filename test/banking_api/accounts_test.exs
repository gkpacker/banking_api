defmodule BankingApi.AccountsTest do
  use BankingApi.DataCase

  alias BankingApi.Accounts

  describe "users" do
    alias BankingApi.Accounts.User

    @valid_attrs %{email: "user@email.com", password: "password"}
    @invalid_attrs %{email: nil, password: nil}
    @invalid_email_attrs %{email: 'email', password: "password"}
    @invalid_password_attrs %{email: 'user@email.com', password: "short"}

    test "get_user!/1 returns the user with given id" do
      created_user = insert(:user)
      user = Accounts.get_user!(created_user.id)

      assert user.id == created_user.id
    end

    test "get_user_by_email!/1 returns the user with given id" do
      created_user = insert(:user)
      user = Accounts.get_user_by_email!(created_user.email)

      assert created_user.id == user.id
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "user@email.com"
      assert Bcrypt.verify_pass("password", user.encrypted_password)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "create_user/1 with existent email returns error changeset" do
      insert(:user, @valid_attrs)

      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@valid_attrs)
    end

    test "create_user/1 with invalid email returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_email_attrs)
    end

    test "create_user/1 with short password returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_password_attrs)
    end
  end
end
