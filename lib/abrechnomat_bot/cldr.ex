defmodule AbrechnomatBot.Cldr do
  use Cldr,
    locales: ["de", "en"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]

  def known_currencies do
    # TODO use Money.Currency.all/0
    [:EUR, :USD]
  end
end
