defmodule AbrechnomatBot.Commands.ExportPayments do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Chat, Bill, Payment}
  alias AbrechnomatBot.I18n

  def command(args) do
    args
    |> parse
    |> execute
  end

  def execute({chat_id, _} = args) do
    Amnesia.transaction do
      execute_for_bill(Bill.find_by_chat(chat_id), args)
    end
  end

  defp execute_for_bill(nil, {chat_id, message_id}) do
    reply("No active bill", chat_id, message_id)
  end

  defp execute_for_bill(%{id: bill_id}, {chat_id, message_id}) do
    i18n =
      chat_id
      |> Chat.find_or_default()
      |> Chat.i18n()

    payments = Payment.by_bill(bill_id)

    fields = ~w(id user date amount own_share text)a

    payment_lines =
      payments
      |> Enum.map(&payment_to_line(&1, fields, i18n))

    file_path = AbrechnomatBot.TempFiles.get_temp_file(export_file_name())
    file = File.open!(file_path, [:utf8, :write])

    try do
      [table_headers(fields) | payment_lines]
      |> CSV.encode()
      |> Enum.each(&IO.write(file, &1))

      File.close(file)

      Telegex.send_document(chat_id, file_path, reply_to_message_id: message_id)
    after
      File.close(file)
      File.rm(file_path)
    end
  end

  defp table_headers(fields) do
    strings = %{
      id: "Id",
      user: "User",
      date: "Date",
      amount: "Amount",
      own_share: "Users own share",
      text: "Text"
    }

    Enum.map(fields, &Map.get(strings, &1))
  end

  defp payment_to_line(payment, keys, i18n) do
    Enum.map(keys, fn key ->
      format_payment_attribute(key, Map.get(payment, key), i18n)
    end)
  end

  defp format_payment_attribute(:user, user, _i18n) do
    Abrechnomat.Users.to_short_string(user)
  end

  defp format_payment_attribute(:date, date, i18n) do
    date
    |> I18n.datetime!(i18n)
  end

  defp format_payment_attribute(:amount, amount, i18n) do
    amount
    |> I18n.money!(i18n, currency_symbol: :none)
  end

  defp format_payment_attribute(_key, value, _i18n) do
    to_string(value)
  end

  defp parse({_, %Telegex.Type.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}) do
    {chat_id, message_id}
  end

  defp reply(text, chat_id, message_id) do
    Telegex.send_message(chat_id, text, reply_to_message_id: message_id)
  end

  defp export_file_name do
    date = DateTime.utc_now()

    "export-#{date.year}-#{date.month}-#{date.day}_#{date.hour}-#{date.minute}.csv"
  end
end
