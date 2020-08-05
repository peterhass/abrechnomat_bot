defmodule AbrechnomatBot.Commands.RevertPayment do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment}

  def command(args) do
    args
    |> parse
    |> case do
      # TODO
      :error -> nil
      parsed -> execute(parsed)
    end
  end

  def execute({payment_id, chat_id, message_id}) do
    Amnesia.transaction do
      case Bill.find_by_chat(chat_id) do
        nil ->
          reply("No active bill", chat_id, message_id)

        %{id: bill_id} ->
          case Payment.delete_by(bill_id: bill_id, payment_id: payment_id) do
            :ok -> reply("Payment #{payment_id} reverted", chat_id, message_id)
            {:error, :not_found} -> reply("Payment #{payment_id} not found", chat_id, message_id)
          end
      end
    end
  end

  defp parse(
         {text, %Nadia.Model.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}
       ) do
    text
    |> String.trim()
    |> Integer.parse()
    |> case do
      :error -> :error
      {payment_id, _} -> {payment_id, chat_id, message_id}
    end
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id)
  end
end
