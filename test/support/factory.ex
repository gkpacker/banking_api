defmodule BankingApi.Factory do
    use ExMachina.Ecto, repo: BankingApi.Repo
  
    alias BankingApi.Accounts.User

    def user_factory do
      %User{
        email: "user@email.com",
        password: "123123"
      }
    end
end
