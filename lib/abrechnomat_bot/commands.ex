defmodule AbrechnomatBot.Commands do
  def command(:handle_payment, options) do
    AbrechnomatBot.Commands.HandlePayment.handle(options)
  end

  def command(_update, _, _) do
    {:error, :noop}
  end
end
