defmodule Abrechnomat.BillingTest do
  use ExUnit.Case
  alias Abrechnomat.Billing
  alias AbrechnomatBot.Database.User

  @christl_id 1
  @christl %User{id: @christl_id, username: "christl"}
  @peter_id 2
  @peter %User{id: @peter_id, username: "peter"}
  @hansi_id 3
  @hansi %User{id: @hansi_id, username: "hansi"}
  @christina_id 4
  @christina %User{id: @christina_id, username: "christina"}
  @herbert_id 9
  @herbert %User{id: @herbert_id, username: "herbert"}

  test "balances_by_user" do
    user_sums = %{
      @christl_id => Money.new(1000, :EUR),
      @peter_id => Money.new(3000, :EUR),
      @hansi_id => Money.new(11000, :EUR)
    }

    user_shares = %{
      @christl_id => Money.new(6167, :EUR),
      @peter_id => Money.new(6666, :EUR),
      @hansi_id => Money.new(2167, :EUR)
    }

    expected_user_balances = %{
      @christl_id => Money.new(5167, :EUR),
      @peter_id => Money.new(3666, :EUR),
      @hansi_id => Money.new(-8833, :EUR)
    }

    assert Billing.balances_by_user(user_sums, user_shares) == expected_user_balances
  end

  test "user_sums_from_ast" do
    ast = [
      {:all, {@hansi_id, Money.new(2000, :EUR)}},
      {:all, {@peter_id, Money.new(3000, :EUR)}},
      {:all_but, {@hansi_id, Money.new(9000, :EUR)}},
      {:all_but, {@christl_id, Money.new(1000, :EUR)}}
    ]

    expected_user_sums = %{
      @christl_id => Money.new(1000, :EUR),
      @peter_id => Money.new(3000, :EUR),
      @hansi_id => Money.new(11000, :EUR)
    }

    assert Billing.user_sums_from_ast(ast) == expected_user_sums
  end

  describe "user_shares_from_ast" do
    test "one single user" do
      ast = [
        {:all, {@hansi_id, Money.new(2000, :EUR)}},
        {:all_but, {@hansi_id, Money.new(9000, :EUR)}}
      ]

      assert Billing.user_shares_from_ast(ast) == {:error, :multiple_users_needed}
    end

    test "multiple users" do
      ast = [
        {:all, {@hansi_id, Money.new(2000, :EUR)}},
        {:all, {@peter_id, Money.new(3000, :EUR)}},
        {:all_but, {@hansi_id, Money.new(9000, :EUR)}},
        {:all_but, {@christl_id, Money.new(1000, :EUR)}}
      ]

      expected_shares = %{
        @christl_id => Money.new(6167, :EUR),
        @hansi_id => Money.new(2166, :EUR),
        @peter_id => Money.new(6667, :EUR)
      }

      assert Billing.user_shares_from_ast(ast) == expected_shares
    end
  end

  test "payment_to_ast" do
    payments = [
      %{user: @hansi, amount: Money.new(2000, :EUR), own_share: nil},
      %{user: @peter, amount: Money.new(3000, :EUR), own_share: nil},
      %{user: @hansi, amount: Money.new(10000, :EUR), own_share: 0.1},
      %{user: @christl, amount: Money.new(1000, :EUR), own_share: 0}
    ]

    expected_ast = [
      {:all, {@hansi_id, Money.new(2000, :EUR)}},
      {:all, {@peter_id, Money.new(3000, :EUR)}},
      {:all_but, {@hansi_id, Money.new(9000, :EUR)}},
      {:all_but, {@christl_id, Money.new(1000, :EUR)}}
    ]

    assert Billing.payment_to_ast(payments) == expected_ast
  end

  test "transactions" do
    user_balances = %{
      @christina_id => %Money{amount: 1000, currency: :EUR},
      @hansi_id => %Money{amount: 4000, currency: :EUR},
      @herbert_id => %Money{amount: -8000, currency: :EUR},
      @peter_id => %Money{amount: 3000, currency: :EUR}
    }

    transactions = Billing.transactions(user_balances)

    sums = account_sums(transactions)
    assert sums[@christina_id] == Money.new(-1000, :EUR)
    assert sums[@hansi_id] == Money.new(-4000, :EUR)
    assert sums[@herbert_id] == Money.new(8000, :EUR)
    assert sums[@peter_id] == Money.new(-3000, :EUR)
    assert length(transactions) <= 5
  end

  test "integration example" do
    payments = [
      %{user: @hansi, amount: Money.new(2000, :EUR), own_share: nil},
      %{user: @peter, amount: Money.new(3000, :EUR), own_share: nil},
      %{user: @herbert, amount: Money.new(10000, :EUR), own_share: nil},
      %{user: @christina, amount: Money.new(1000, :EUR), own_share: nil},
      %{user: @herbert, amount: Money.new(3000, :EUR), own_share: 0},
      %{user: @christina, amount: Money.new(6000, :EUR), own_share: 0.5}
    ]

    ast = Billing.payment_to_ast(payments)
    user_shares = Billing.user_shares_from_ast(ast)
    user_sums = Billing.user_sums_from_ast(ast)
    user_balances = Billing.balances_by_user(user_sums, user_shares)
    transactions = Billing.transactions(user_balances)

    sums = account_sums(transactions)

    assert sums[@peter_id] == Money.new(-3000, :EUR)
    assert sums[@hansi_id] == Money.new(-4000, :EUR)
    assert sums[@herbert_id] == Money.new(8000, :EUR)
    assert sums[@christina_id] == Money.new(-1000, :EUR)
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
