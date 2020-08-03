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
      |> Enum.min

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

  # returns user and how much he needs to receive (positive number) or pay (negative number)
  # peter => +300 EUR  - has to pay other people 300 eur
  # hans => -20 EUR - needs to receive 20 eur
  def balances_by_user(user_sums) do
    total = Map.values(user_sums) |> Enum.reduce(Money.new(0, :EUR), &Money.add(&2, &1))

    # TODO: should be flexible (not everybody pays the same percentage)
    users = Map.keys(user_sums)

    shares =
      users
      |> Stream.zip(Money.divide(total, Enum.count(users)))
      |> Enum.into(%{})

    Enum.map(user_sums, fn {username, balance} ->
      diff = Money.subtract(balance, shares[username])
             |> Money.multiply(-1) # TODO: refactor
      {username, diff}
    end)
    |> Enum.into(%{})
  end
end
