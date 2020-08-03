defmodule AbrechnomatBot.Commands.HandlePayment.Parser do
  @handle_payment_regex ~r{
        ^
        \s*
        (
          (?<user>@[A-z0-9_]+)
          \s*
        )?
        (?<amount>[0-9]*([\.|\,][0-9]*)?)\s*
        (EUR|€)?\s*
        (?<text>.*)?
      }x

  def parse({
        message_text,
        %Nadia.Model.Update{
          message: %{
            message_id: message_id, 
            date: date,
            chat: %{id: chat_id},
            from: %{id: from_id, username: from_username}
          }
        }
      }) do
    %{"amount" => amount, "user" => user, "text" => text} =
      Regex.named_captures(@handle_payment_regex, message_text)

    %{
      message_id: message_id, 
      chat_id: chat_id,
      date: DateTime.from_unix!(date),
      amount: parse_amount(amount),
      user: user |> normalize_user |> clear_empty_string,
      text: text,
      from_id: from_id,
      from_username: from_username
    }
  end

  defp normalize_user(user) do
    Regex.replace(~r/^@/, user, "")
  end

  defp parse_amount(amount) do
    Money.parse!(amount, :EUR, separator: ".", delimiter: ",")
  end

  defp clear_empty_string(""), do: nil
  defp clear_empty_string(str), do: str
end
