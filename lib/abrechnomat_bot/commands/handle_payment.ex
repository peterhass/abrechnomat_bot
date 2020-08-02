defmodule AbrechnomatBot.Commands.HandlePayment do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment}
  alias __MODULE__.Parser

  def command(args) do
    args
    |> Parser.parse()
    |> execute
  end

  def execute(%{
        chat_id: chat_id,
        message_id: message_id,
        user: user,
        from_username: from_username,
        date: date,
        amount: amount,
        text: text
      }) do
    Amnesia.transaction do
      Bill.find_or_create_by_chat(chat_id)
      |> Bill.add_payment(user || from_username, date, amount, text)
      |> payment_message
      |> reply(chat_id, message_id)
    end
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id)
  end

  def payment_message(%Payment{user: user, date: date, amount: amount, text: text}) do
    [
      "Added following payment ...",
      "@#{user}",
      "#{date}",
      "#{amount}",
      "Text: #{text}"
    ]
    |> Enum.join("\n")
  end
end
