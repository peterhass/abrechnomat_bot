defmodule Abrechnomat.Billing do
  def sums_by_user(payments) do
    reducer = fn payment, acc ->
      sum = Map.get_lazy(acc, payment.user, fn -> Money.new(0, :EUR) end)
      |> Money.add(payment.amount)

      Map.put(acc, payment.user, sum)
    end

    Enum.reduce(payments, %{}, reducer)
  end

  def get_pay_instructions() do
    [
      # https://stackoverflow.com/a/877832
      # split in creditors and debitors
      {:peter, :hans, 23},
      {:hans, :tony, 10}
    ]
  end

  # returns user and how much he needs to receive (positive number) or pay (negative number)
  # peter => +300 EUR  - has to pay other people 300 eur
  # hans => -20 EUR - needs to receive 20 eur
  def balances_by_user(user_sums) do
    total = Map.values(user_sums) |> Enum.reduce(Money.new(0, :EUR), &Money.add(&2, &1))

    # TODO: should be flexible (not everybody pays the same percentage)
    users = Map.keys(user_sums)
    shares = users
      |> Stream.zip(Money.divide(total, Enum.count(users)))
      |> Enum.into(%{})

    Enum.map(user_sums, fn {username, balance} ->
      diff = Money.subtract(balance, shares[username])
      {username, diff}
    end)
    |> Enum.into(%{})
  end

end
