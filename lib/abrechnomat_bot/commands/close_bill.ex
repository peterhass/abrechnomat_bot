defmodule AbrechnomatBot.Commands.CloseBill do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill}

  def command(args) do
    args
    |> parse
    |> execute
  end

  def command_callback(args) do
    args
    |> parse
    |> execute
  end

  def execute({:check, {chat_id, message_id}}) do
    reply_markup = %Nadia.Model.InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %{
            callback_data: "/close_bill SURE",
            text: "YES, I am sure I want to close the current bill"
          }
        ]
      ]
    }

    Nadia.send_message(chat_id, "Are you sure?",
      reply_to_message_id: message_id,
      reply_markup: reply_markup
    )
  end

  def execute({:execute, {chat_id, message_id, bot_message_id}}) do
    Nadia.delete_message(chat_id, bot_message_id)

    Amnesia.transaction do
      case Bill.find_by_chat(chat_id) do
        nil ->
          reply("No active bill", chat_id, message_id)

        %{id: bill_id} ->
          # TODO: extract parts
          AbrechnomatBot.Commands.ExportPayments.execute({chat_id, message_id})
          AbrechnomatBot.Commands.BillStats.execute({chat_id, message_id})

          case Bill.delete_with_payments(bill_id) do
            :ok -> reply("Bill closed", chat_id, message_id)
          end
      end
    end
  end

  defp parse(
         {text,
          %Nadia.Model.Update{
            callback_query: %{
              message: %{
                reply_to_message: %{message_id: message_id},
                message_id: bot_message_id,
                chat: %{id: chat_id}
              }
            }
          }}
       ) do
    {parse_message_text(text), {chat_id, message_id, bot_message_id}}
  end

  defp parse({_, %Nadia.Model.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}) do
    {:check, {chat_id, message_id}}
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id)
  end

  defp parse_message_text(" SURE") do
    :execute
  end

  defp parse_message_text(_) do
    :check
  end
end
