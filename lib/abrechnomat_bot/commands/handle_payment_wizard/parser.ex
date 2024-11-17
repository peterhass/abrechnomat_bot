defmodule AbrechnomatBot.Commands.HandlePaymentWizard.Parser do
  def parse_amount(text) do
    case Money.parse(text, :EUR, separator: ".", delimiter: ",") do
      {:ok, money} -> {:ok, money}
      :error -> :error
    end
  end

  def parse_share(text) do
    case Integer.parse(text, 10) do
      :error -> :error
      {num, _} when num > 100 -> :error
      {num, _} when num == 0 -> :error
      {num, _}  -> {:ok, num / 100}
    end
  end
end
