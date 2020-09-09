defmodule BankingApi.IntegrationCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      use Hound.Helpers

      import Ecto
      import Ecto.Query, only: [from: 2]
      import BankingApiWeb.Router
      import BankingApi.Factory

      alias BankingApi.Repo

      # The default endpoint for testing
      @endpoint BankingApi.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(BankingApi.Repo)

    unless tags[:async] do
      Sandbox.mode(BankingApi.Repo, {:shared, self()})
    end

    :ok
  end
end
