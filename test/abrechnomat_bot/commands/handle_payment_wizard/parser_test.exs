defmodule AbrechnomatBot.Commands.HandlePaymentWizard.ParserTest do
  use ExUnit.Case, async: true

  alias AbrechnomatBot.Commands.HandlePaymentWizard.Parser
  alias AbrechnomatBot.I18n

  describe "parse_amount" do
    test "parses german euro amounts" do
      i18n = I18n.init(%{currency: "EUR", locale: "de", time_zone: "UTC"})

      assert Parser.parse_amount("2.300,20 EUR", i18n) == {:ok, Money.new(230_020, "EUR")}
    end

    test "parses english eur amounts" do
      i18n = I18n.init(%{currency: "EUR", locale: "en", time_zone: "UTC"})

      assert Parser.parse_amount("2,300.20 EUR", i18n) == {:ok, Money.new(230_020, "EUR")}
    end

    test "returns error for invalid numbers" do
      i18n = I18n.init(%{currency: "EUR", locale: "en", time_zone: "UTC"})

      assert Parser.parse_amount("fifty EUR", i18n) == :error
    end
  end
end
