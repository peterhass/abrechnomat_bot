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

  # TODO: print usage if something went wrong during parsing

  def execute(%{
        chat_id: chat_id,
        message_id: message_id,
        user: user,
        from_username: from_username,
        date: date,
        amount: amount,
        own_share: own_share,
        text: text
      }) do
    Amnesia.transaction do
      Bill.find_or_create_by_chat(chat_id)
      |> Bill.add_payment(user || from_username, date, amount, own_share, text)
      |> payment_message
      |> reply(chat_id, message_id)
    end
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id)
  end

  def payment_message(%Payment{id: id, user: user, date: date, amount: amount, text: text} = payment) do
    [
      "Added following payment ...",
      "ID: #{id}",
      "@#{user}",
      "#{date}",
      "#{amount}",
      payment_message_share(payment),
      "Text: #{text}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp payment_message_share(%Payment{amount: _, own_share: own_share}) when is_nil(own_share) do
    nil
  end

  defp payment_message_share(%Payment{amount: amount, own_share: own_share}) do
    "own share: #{own_share}% = #{Money.multiply(amount, own_share)}"
  end
end
