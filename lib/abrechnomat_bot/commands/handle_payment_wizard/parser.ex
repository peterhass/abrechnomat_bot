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

  def parse_text(text) do
    trimmed = String.trim(text)

    case String.length(text) do
      len when len > 3000 -> {:error, :too_long} # should be able to fit an URL
      len when len == 0 -> {:error, :empty}
      _ -> {:ok, trimmed}
    end
  end
end
