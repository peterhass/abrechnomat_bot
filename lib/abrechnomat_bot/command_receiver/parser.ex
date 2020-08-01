defmodule AbrechnomatBot.CommandReceiver.Parser do
  def parse(
    %{
      message: %{
        text: "/add_payment " <> options
      }
    }
  ) do
    {:ok, :handle_payment, payment_options(options)}
  end

  def parse(%Nadia.Model.Update{}) do
    {:error, :noop}
  end

  defp payment_options(str) do

  end

end
