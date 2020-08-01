defmodule AbrechnomatBot.CommandReceiver.Parser do
  @handle_payment_regex ~r{
      ^(
        (?<user>@[A-z0-9]+)
        \s
      )?
      (?<amount>[0-9]*([\.|\,][0-9]*)?)
      (\s?EUR|€)?\s
      (?<text>.*)
    }x

  def parse(%{
        message: %{
          text: "/add_payment " <> message_text,
          date: date,
          chat: %{id: chat_id},
          from: %{id: from_id, username: from_username}
        }
      }) do
    %{"amount" => amount, "user" => user, "text" => text} =
      Regex.named_captures(@handle_payment_regex, message_text)

    payment_options = %{
      chat_id: chat_id,
      date: DateTime.from_unix!(date),
      amount: normalize_amount(amount),
      user: user |> normalize_user |> clear_empty_string,
      text: text,
      from_id: from_id,
      from_username: from_username
    }

    {:ok, :handle_payment, payment_options}
  end

  def parse(%Nadia.Model.Update{}) do
    {:error, :noop}
  end

  defp normalize_user(user) do
    Regex.replace(~r/^@/, user, "")
  end

  defp normalize_amount(amount) do
    String.replace(amount, ",", ".")
  end

  defp clear_empty_string(""), do: nil
  defp clear_empty_string(str), do: str
end
