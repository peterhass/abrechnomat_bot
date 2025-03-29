defmodule AbrechnomatBot.Commands.RevertPayment do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment}
  import Phoenix.HTML

  def command(args) do
    args
    |> parse
    |> execute
  end

  def execute({:ok, {payment_id, chat_id, message_id}}) do
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

  def execute({:error, _, {chat_id, message_id}}) do
    usage()
    |> reply(chat_id, message_id)
  end

  defp usage do
    cmd_usage = "/revert_payment [id]"
    text = "Use ID from bot's response to /add_payment"

    ~E"""
    <code><%= cmd_usage %></code>
    <%= text %>
    """
    |> safe_to_string
  end

  defp parse(
         {text, %Telegex.Type.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}
       ) do
    text
    |> String.trim()
    |> Integer.parse()
    |> case do
      :error -> {:error, :invalid_payment_id, {chat_id, message_id}}
      {payment_id, _} -> {:ok, {payment_id, chat_id, message_id}}
    end
  end

  defp reply(text, chat_id, message_id) do
    Telegex.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "HTML")
  end
end
