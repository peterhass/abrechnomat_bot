defmodule AbrechnomatBot.Commands.HandlePaymentWizard.Parser do
  def parse_amount(text) do
    case Money.parse(text, :EUR, separator: ".", delimiter: ",") do
      {:ok, money} -> {:ok, money}
      :error -> :error
    end
  end
end
