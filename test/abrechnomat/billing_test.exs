defmodule Abrechnomat.BillingTest do
  use ExUnit.Case
  alias Abrechnomat.Billing

  describe "transactions" do
    test "after transactions all accounts are balanced" do
      transactions =
        Billing.transactions(%{
          "peter" => Money.new(40, :EUR),
          "hansi" => Money.new(10, :EUR),
          "herbert" => Money.new(-20, :EUR),
          "christina" => Money.new(-30, :EUR)
        })

      sums = account_sums(transactions)

      assert sums["peter"] == Money.new(-40, :EUR)
      assert sums["hansi"] == Money.new(-10, :EUR)
      assert sums["herbert"] == Money.new(20, :EUR)
      assert sums["christina"] == Money.new(30, :EUR)
    end

    # TODO: test balances_by_user
  end

  def account_sums(transactions) do
    Enum.reduce(transactions, %{}, fn {from, to, amount}, acc ->
      acc
      |> update_account_sum(from, Money.neg(amount))
      |> update_account_sum(to, amount)
    end)
  end

  def update_account_sum(map, username, amount) do
    sum =
      Map.get(map, username, Money.new(0, :EUR))
      |> Money.add(amount)

    Map.put(map, username, sum)
  end
end
