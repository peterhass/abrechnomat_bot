defmodule AbrechnomatBot.Commands do
  def command(%Nadia.Model.Update{ message: %{ text: "/add_payment" <> text }} = update) do
    AbrechnomatBot.Commands.HandlePayment.command({text, update})
  end

  def command(%Nadia.Model.Update{}) do
    {:error, :noop}
  end
end
