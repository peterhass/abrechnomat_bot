defmodule AbrechnomatBot.Commands.CloseBill do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill}

  def command(args) do
    args
    |> parse
    |> execute
  end

  def execute({chat_id, message_id}) do
    Amnesia.transaction do
      case Bill.find_by_chat(chat_id) do
        nil ->
          reply("No active bill", chat_id, message_id)

        %{id: bill_id} ->
          # TODO: extract parts
          AbrechnomatBot.Commands.BillStats.execute({chat_id, message_id})

          case Bill.delete_with_payments(bill_id) do
            :ok -> reply("Bill closed", chat_id, message_id)
          end
      end
    end
  end

  defp parse({_, %Nadia.Model.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}) do
    {chat_id, message_id}
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id)
  end
end
