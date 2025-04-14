defmodule AbrechnomatBot.Commands.HandlePaymentWizard.Parser do
  alias AbrechnomatBot.Cldr

  def parse_amount(text, i18n) do
    first_decimal =
      Cldr.Number.scan(text, locale: i18n.locale, number: :decimal)
      |> Enum.find(fn item ->
        case item do
          %Decimal{} -> true
          _ -> false
        end
      end)

    with decimal when not is_nil(decimal) <- first_decimal,
         {:ok, money} <- Money.parse(decimal, i18n.currency) do
      {:ok, money}
    else
      _ -> :error
    end
  end

  def parse_share(text) do
    case Integer.parse(text, 10) do
      :error -> :error
      {num, _} when num > 100 -> :error
      {num, _} when num == 0 -> :error
      {num, _} -> {:ok, num / 100}
    end
  end

  def parse_text(text) do
    trimmed = String.trim(text)

    case String.length(text) do
      # should be able to fit an URL
      len when len > 3000 -> {:error, :too_long}
      len when len == 0 -> {:error, :empty}
      _ -> {:ok, trimmed}
    end
  end
end
