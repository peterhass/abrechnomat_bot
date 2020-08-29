defmodule Abrechnomat.Billing do
  def sums_by_user(payments) do
    reducer = fn payment, acc ->
      sum =
        Map.get_lazy(acc, payment.user, fn -> Money.new(0, :EUR) end)
        |> Money.add(payment.amount)

      Map.put(acc, payment.user, sum)
    end

    Enum.reduce(payments, %{}, reducer)
  end

  def transactions(user_balances) when map_size(user_balances) <= 1 do
    []
  end

  def transactions(user_balances) do
    {creditors, debitors} = get_user_balances_groups(user_balances)

    transactions(
      List.pop_at(debitors, 0),
      List.pop_at(creditors, 0)
    )
  end

  def transactions(
        {{debitor_key, debitor_amount}, _} = debitor_pair,
        {{creditor_key, creditor_amount}, _} = creditor_pair
      ) do
    transaction_amount =
      [debitor_amount, creditor_amount]
      |> Enum.map(&Money.abs/1)
      |> Enum.min()

    transaction = {debitor_key, creditor_key, transaction_amount}

    [transaction] ++
      transactions(
        select_user(debitor_pair, transaction_amount),
        select_user(creditor_pair, transaction_amount)
      )
  end

  def transactions({nil, []}, {nil, []}) do
    []
  end

  defp get_user_balances_groups(user_balances) do
    groups =
      user_balances
      |> Enum.sort_by(fn {_, amount} -> amount end)
      |> Enum.group_by(fn {_, amount} -> Money.negative?(amount) end)

    creditors = Map.get(groups, true, [])
    debitors = Map.get(groups, false, [])

    {creditors, debitors}
  end

  # TODO: rename
  defp select_user({{user_key, user_amount}, users}, amount) do
    remaining_balance =
      user_amount
      |> Money.abs()
      |> Money.subtract(amount)

    if Money.positive?(remaining_balance) do
      {{user_key, remaining_balance}, users}
    else
      List.pop_at(users, 0)
    end
  end

  def balances_by_user(user_sums, user_shares) do
    Enum.map(user_sums, fn {username, sum} ->
      diff =
        Money.subtract(sum, user_shares[username])
        # TODO: refactor
        |> Money.multiply(-1)

      {username, diff}
    end)
    |> Enum.into(%{})
  end

  def user_sums_from_ast(ast) do
    Enum.reduce(ast, %{}, fn {_, {user, amount}}, acc ->
      Map.new([{user, amount}])
      |> Enum.into(%{})
      |> Map.merge(acc, &map_merge_money_add/3)
    end)
  end

  def user_shares_from_ast(ast) do
    users =
      Enum.reduce(ast, MapSet.new(), fn {_, {user, _}}, acc ->
        MapSet.put(acc, user)
      end)
      |> MapSet.to_list()

    user_shares_from_ast(ast, users)
  end

  def user_shares_from_ast(_, [_]) do
    {:error, :multiple_users_needed}
  end

  def user_shares_from_ast(ast, users) do
    Enum.reduce(ast, %{}, fn
      {:all, {_, amount}}, acc ->
        users
        |> Stream.zip(Money.divide(amount, Enum.count(users)))
        |> Enum.into(%{})
        |> Map.merge(acc, &map_merge_money_add/3)

      {:all_but, {user, amount}}, acc ->
        users
        |> Enum.reject(&(&1 == user))
        |> Stream.zip(Money.divide(amount, Enum.count(users) - 1))
        |> Enum.into(%{})
        |> Map.merge(acc, &map_merge_money_add/3)
    end)
  end

  def map_merge_money_add(_k, value1, value2) do
    Money.add(value1, value2)
  end

  def payment_to_ast(payments) when is_list(payments) do
    Enum.map(payments, &payment_to_ast/1)
  end

  def payment_to_ast(%{amount: amount, own_share: own_share, user: user})
      when is_nil(own_share) do
    {:all, {user.id, amount}}
  end

  def payment_to_ast(%{amount: amount, own_share: own_share, user: user}) do
    {:all_but, {user.id, Money.multiply(amount, 1 - own_share)}}
  end
end
