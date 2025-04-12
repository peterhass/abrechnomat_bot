defmodule AbrechnomatBot.I18n do
  defmodule Context do
    defstruct [:locale, :currency]
  end

  alias AbrechnomatBot.Cldr

  def init(%{locale: locale, currency: currency}) do
    %Context{locale: locale, currency: currency}
  end

  def datetime!(
    datetime,
    %Context{locale: locale},
    options \\ []
  ) do
    Cldr.DateTime.to_string!(datetime, Keyword.merge([locale: locale], options))
  end

  def money!(
    amount,
    %Context{locale: locale, currency: currency},
    options \\ []
  ) do
    amount
    |> Money.to_decimal()
    |> Decimal.to_float
    |> Cldr.Number.to_string!(Keyword.merge([locale: locale, currency: currency], options))   
  end
end
