defmodule AbrechnomatBot.I18n do
  defmodule Context do
    defstruct [:locale, :currency, :time_zone]
  end

  alias AbrechnomatBot.Cldr

  def init(%{
        locale: locale,
        currency: currency,
        time_zone: time_zone
      }) do
    %Context{locale: locale, currency: currency, time_zone: time_zone}
  end

  def datetime!(
        datetime,
        %Context{locale: locale, time_zone: time_zone},
        options \\ []
      ) do
    local_datetime = DateTime.shift_zone!(datetime, time_zone)
    Cldr.DateTime.to_string!(local_datetime, Keyword.merge([locale: locale], options))
  end

  def money!(
        amount,
        %Context{locale: locale, currency: currency},
        options \\ []
      ) do
    amount
    |> Money.to_decimal()
    |> Decimal.to_float()
    |> Cldr.Number.to_string!(Keyword.merge([locale: locale, currency: currency], options))
  end
end
