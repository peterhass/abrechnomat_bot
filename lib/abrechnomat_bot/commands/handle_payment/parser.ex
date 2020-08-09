defmodule AbrechnomatBot.Commands.HandlePayment.Parser do
  @handle_payment_regex ~r"
        ^
        \s*
        (
          (?<user>@[A-z0-9_]+)
          \s*
        )?
        (?<amount>[0-9]*([\.|\,][0-9]*)?)\s*
        (\((?<own_share>[0-9]{1,2})%?\))?\s*
        (EUR|€)?\s*
        (?<text>.*)?
      "x

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
    %{"amount" => amount, "own_share" => own_share, "user" => user, "text" => text} =
      Regex.named_captures(@handle_payment_regex, message_text)

    %{
      message_id: message_id, 
      chat_id: chat_id,
      date: DateTime.from_unix!(date),
      amount: parse_amount(amount),
      own_share: parse_share(own_share),
      user: user |> normalize_user |> clear_empty_string,
      text: text,
      from_id: from_id,
      from_username: from_username
    }
    |> transform_errors
  end

  defp transform_errors(%{amount: :error, own_share: :error} = parsed) do
    {:error, :amount_and_own_share_invalid, parsed}
  end

  defp transform_errors(%{amount: :error} = parsed) do
    {:error, :amount_invalid, parsed}
  end

  defp transform_errors(%{own_share: :error} = parsed) do
    {:error, :amount_invalid, parsed}
  end

  defp transform_errors(parsed) do
    {:ok, parsed}
  end


  defp parse_share(""), do: nil

  defp parse_share(share) do
    case Integer.parse(share, 10) do
      :error -> :error
      {num, _} -> num / 100
    end
  end

  defp normalize_user(user) do
    Regex.replace(~r/^@/, user, "")
  end

  defp parse_amount(amount) do
    case Money.parse(amount, :EUR, separator: ".", delimiter: ",") do
      {:ok, money} -> money
      :error -> :error
    end
  end

  defp clear_empty_string(""), do: nil
  defp clear_empty_string(str), do: str
end
