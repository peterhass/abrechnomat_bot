defmodule AbrechnomatBot.Commands.SetLocale do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Chat}
  import Phoenix.HTML

  def command(args) do
    args
    |> parse
    |> execute
  end

  defp execute({:ok, {locale, currency, time_zone, chat_id, message_id}}) do
    Amnesia.transaction do
      chat = Chat.find_or_default(chat_id)

      %{} =
        %{chat | currency: currency, locale: locale, time_zone: time_zone}
        |> Chat.write()

      reply(
        "Set locale to '#{locale}', currency to '#{currency}' and time-zone to '#{time_zone}'",
        chat_id,
        message_id
      )
    end
  end

  defp execute({:error, _, {chat_id, message_id}}) do
    usage()
    |> reply(chat_id, message_id)
  end

  defp usage do
    locales = Enum.join(available_locales(), ", ")
    currencies = Enum.join(available_currencies(), ", ")

    time_zones =
      Zoneinfo.time_zones()
      |> Enum.filter(fn time_zone ->
        patterns = ["Europe", "Asia", "America"]
        String.starts_with?(time_zone, patterns)
      end)
      |> Enum.take_random(10)
      |> Enum.map(fn time_zone -> "- #{time_zone}" end)
      |> Enum.join("\n")

    cmd_usage = "/set_locale [locale] [currency] [time_zone]"

    ~E"""
    <code><%= cmd_usage %></code>

    Configure locale settings for the current chat.

    Valid locales: <%= locales %>
    Valid currencies: <%= currencies %>
    Valid time-zones: 
    - ...
    <%= time_zones %>
    - ...
    """
    |> safe_to_string
  end

  defp parse(
         {text, %Telegex.Type.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}
       ) do
    input_parts = String.split(text, " ", trim: true)

    with [raw_locale, raw_currency, raw_time_zone] <- input_parts,
         {:ok, locale} <- parse_locale(raw_locale),
         {:ok, currency} <- parse_currency(raw_currency),
         {:ok, time_zone} <- parse_time_zone(raw_time_zone) do
      {:ok, {locale, currency, time_zone, chat_id, message_id}}
    else
      _ -> {:error, :unknown, {chat_id, message_id}}
    end
  end

  defp parse_locale(input_locale) do
    locale = String.downcase(input_locale)

    Enum.member?(available_locales(), locale)
    |> case do
      true -> {:ok, locale}
      false -> {:error}
    end
  end

  defp parse_currency(input_currency) do
    currency = String.upcase(input_currency)

    Enum.member?(available_currencies(), currency)
    |> case do
      true -> {:ok, currency}
      false -> {:error}
    end
  end

  defp parse_time_zone(input_zone) do
    Zoneinfo.valid_time_zone?(input_zone)
    |> case do
      true -> {:ok, input_zone}
      false -> {:error}
    end
  end

  defp reply(text, chat_id, message_id) do
    Telegex.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "HTML")
  end

  defp available_locales do
    AbrechnomatBot.Cldr.known_locale_names()
    |> Enum.map(&to_string/1)
  end

  defp available_currencies do
    AbrechnomatBot.Cldr.known_currencies()
    |> Enum.map(&to_string/1)
  end
end
