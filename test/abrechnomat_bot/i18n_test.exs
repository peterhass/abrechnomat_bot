defmodule AbrechnomatBot.I18nTest do
  use ExUnit.Case, async: true
  alias AbrechnomatBot.I18n

  test "datetime!" do
    i18n =
      I18n.init(%{
        locale: "de",
        currency: "EUR",
        time_zone: "Europe/Berlin"
      })

    datetime = ~U[2025-04-14 22:17:03Z]

    assert I18n.datetime!(datetime, i18n) == "15.04.2025, 00:17:03"
  end

  describe "money!" do
    test "format without symbol" do
      i18n =
        I18n.init(%{
          locale: "de",
          currency: "EUR",
          time_zone: "Europe/Berlin"
        })

      amount = Money.new(1201, :EUR)

      assert I18n.money!(amount, i18n, currency_symbol: :none) == "12,01"
    end
  end
end
