defmodule BankingApi.AccountsTest do
  use BankingApi.DataCase

  alias BankingApi.Accounts

  describe "users" do
    alias BankingApi.Accounts.User

    @valid_attrs %{email: "user@email.com", password: "password"}
    @update_attrs %{email: "updated@email.com", password: "updated_password"}
    @invalid_attrs %{email: nil, password: nil}
    @invalid_email_attrs %{email: 'email', password: "password"}
    @invalid_password_attrs %{email: 'user@email.com', password: "short"}

    def user_fixture(attrs \\ %{}) do
      user = insert(:user, attrs)

      %User{user | password: nil}
    end
      
    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      created_user = user_fixture()
      user = Accounts.get_user!(created_user.id)

      assert user == created_user
      assert user.password == nil
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
      user_fixture(@valid_attrs)

      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@valid_attrs)
    end

    test "create_user/1 with invalid email returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_email_attrs)
    end

    test "create_user/1 with short password returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_password_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "updated@email.com"
      assert Bcrypt.verify_pass("updated_password", user.encrypted_password)
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
