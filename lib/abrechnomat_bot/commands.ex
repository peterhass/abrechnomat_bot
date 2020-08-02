defmodule AbrechnomatBot.Commands do
  alias __MODULE__.{
    HandlePayment, 
    BillStats
  }

  def command(%Nadia.Model.Update{message: %{text: "/add_payment" <> text}} = update) do
    HandlePayment.command({text, update})
  end

  def command(%Nadia.Model.Update{message: %{text: "/bill_stats" <> text}} = update) do
    BillStats.command({text, update})
  end

  def command(%Nadia.Model.Update{}) do
    {:error, :noop}
  end
end
