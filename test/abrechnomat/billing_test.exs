defmodule Abrechnomat.BillingTest do
  use ExUnit.Case
  alias Abrechnomat.Billing

  test "balances_by_user" do
    user_sums = %{
      "christl" => Money.new(1000, :EUR),
      "peter" => Money.new(3000, :EUR),
      "hansi" => Money.new(11000, :EUR),
    }

    user_shares = %{
      "christl" => Money.new(6167, :EUR),
      "peter" => Money.new(6666, :EUR),
      "hansi" => Money.new(2167, :EUR),
    }

    expected_user_balances = %{
      "christl" => Money.new(5167, :EUR),
      "peter" => Money.new(3666, :EUR),
      "hansi" => Money.new(-8833, :EUR),
    }

    assert Billing.balances_by_user(user_sums, user_shares) == expected_user_balances
  end


  test "user_sums_from_ast" do
    ast = [
      {:all, {"hansi", Money.new(2000, :EUR)}},
      {:all, {"peter", Money.new(3000, :EUR)}},
      {:all_but, {"hansi", Money.new(9000, :EUR)}},
      {:all_but, {"christl", Money.new(1000, :EUR)}}
    ]
    
    expected_user_sums = %{
      "christl" => Money.new(1000, :EUR),
      "peter" => Money.new(3000, :EUR),
      "hansi" => Money.new(11000, :EUR),
    }

    assert Billing.user_sums_from_ast(ast) == expected_user_sums
  end

  test "user_shares_from_ast" do
    ast = [
      {:all, {"hansi", Money.new(2000, :EUR)}},
      {:all, {"peter", Money.new(3000, :EUR)}},
      {:all_but, {"hansi", Money.new(9000, :EUR)}},
      {:all_but, {"christl", Money.new(1000, :EUR)}}
    ]
    
    expected_shares = %{
      "christl" => Money.new(6167, :EUR),
      "hansi" => Money.new(2167, :EUR),
      "peter" => Money.new(6666, :EUR),
    }

    assert Billing.user_shares_from_ast(ast) == expected_shares
  end
  
  test "payment_to_ast" do
    payments = [
      %{user: "hansi", amount: Money.new(2000, :EUR), own_share: nil}, 
      %{user: "peter", amount: Money.new(3000, :EUR), own_share: nil}, 
      %{user: "hansi", amount: Money.new(10000, :EUR), own_share: 0.1}, 
      %{user: "christl", amount: Money.new(1000, :EUR), own_share: 0}, 
    ]

    expected_ast = [
    {:all, {"hansi", Money.new(2000, :EUR)}},
    {:all, {"peter", Money.new(3000, :EUR)}},
    {:all_but, {"hansi", Money.new(9000, :EUR)}},
    {:all_but, {"christl", Money.new(1000, :EUR)}}
    ]

    assert Billing.payment_to_ast(payments) == expected_ast
  end

  test "transactions" do
    user_balances = %{
      "christina" => %Money{amount: 1000, currency: :EUR},
      "hansi" => %Money{amount: 4000, currency: :EUR},
      "herbert" => %Money{amount: -8000, currency: :EUR},
      "peter" => %Money{amount: 3000, currency: :EUR}   
    }

    transactions = Billing.transactions(user_balances)

    sums = account_sums(transactions)
    assert sums["christina"] == Money.new(-1000, :EUR)
    assert sums["hansi"] == Money.new(-4000, :EUR)
    assert sums["herbert"] == Money.new(8000, :EUR)
    assert sums["peter"] == Money.new(-3000, :EUR)
    assert length(transactions) <= 5
  end

  test "integration example" do
    payments = [
      %{user: "hansi", amount: Money.new(2000, :EUR), own_share: nil}, 
      %{user: "peter", amount: Money.new(3000, :EUR), own_share: nil}, 
      %{user: "herbert", amount: Money.new(10000, :EUR), own_share: nil}, 
      %{user: "christina", amount: Money.new(1000, :EUR), own_share: nil}, 
      %{user: "herbert", amount: Money.new(3000, :EUR), own_share: 0}, 
      %{user: "christina", amount: Money.new(6000, :EUR), own_share: 0.5}, 
    ]

    ast = Billing.payment_to_ast(payments)
    user_shares = Billing.user_shares_from_ast(ast)
    user_sums = Billing.user_sums_from_ast(ast)
    user_balances = Billing.balances_by_user(user_sums, user_shares)
    transactions = Billing.transactions(user_balances)

    sums = account_sums(transactions)

    assert sums["peter"] == Money.new(-3000, :EUR)
    assert sums["hansi"] == Money.new(-4000, :EUR)
    assert sums["herbert"] == Money.new(8000, :EUR)
    assert sums["christina"] == Money.new(-1000, :EUR)
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
