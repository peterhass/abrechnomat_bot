defmodule AbrechnomatBot.Commands.HandlePayment.Parser do
  alias AbrechnomatBot.Cldr

  @handle_payment_regex ~r"
        ^
        \s*
        (?<amount>[0-9\.\,]*)\s*
        (\((?<own_share>[0-9]{1,2})%?\))?\s*
        (EUR|€)?\s*
        (?<text>.*)?
      "x

  def parse(
        {
          _,
          %Telegex.Type.Update{
            message: %{
              entities: entities,
              message_id: message_id,
              date: date,
              chat: %{id: chat_id},
              from: from_user,
              text: message_text
            }
          }
        },
        i18n
      ) do
    [remaining_text, user] = get_target_user(message_text, entities)

    %{"amount" => amount, "own_share" => own_share, "text" => text} =
      Regex.named_captures(@handle_payment_regex, remaining_text)

    %{
      message_id: message_id,
      chat_id: chat_id,
      date: DateTime.from_unix!(date),
      amount: parse_amount(amount, i18n),
      own_share: parse_share(own_share),
      user: user || from_user,
      text: text
    }
    |> transform_errors
  end

  def get_target_user(text, [
        %{type: "bot_command", length: _},
        %{type: "text_mention", length: mention_length, offset: mention_offset, user: user}
        | _
      ]) do
    remaining_text =
      text
      |> String.slice((mention_offset + mention_length)..String.length(text))

    [remaining_text, user]
  end

  def get_target_user(text, [
        %{type: "bot_command", length: _},
        %{type: "mention", length: mention_length, offset: mention_offset}
        | _
      ]) do
    remaining_text =
      text
      |> String.slice((mention_offset + mention_length)..String.length(text))

    username =
      text
      |> String.slice(mention_offset..(mention_offset + mention_length - 1))

    stripped_username =
      ~r/^@/
      |> Regex.replace(username, "")

    [
      remaining_text,
      %Telegex.Type.User{username: stripped_username, id: nil, is_bot: false, first_name: nil}
    ]
  end

  def get_target_user(text, [
        %{type: "bot_command", length: command_length}
        | _
      ]) do
    remaining_text =
      text
      |> String.slice(command_length..String.length(text))

    [remaining_text, nil]
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

  defp parse_amount(text, i18n) do
    first_decimal =
      Cldr.Number.scan(text, locale: i18n.locale, number: :decimal)
      |> Enum.find(fn item ->
        case item do
          %Decimal{} -> true
          _ -> false
        end
      end)

    with decimal when not is_nil(decimal) <- first_decimal,
         {:ok, money} <- Money.parse(decimal, i18n.currency) do
      money
    else
      _ -> :error
    end
  end
end
