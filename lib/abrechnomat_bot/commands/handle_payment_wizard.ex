defmodule AbrechnomatBot.Commands.HandlePaymentWizard do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Commands.MessageContextStore

  def command(args) do
    args
    |> parse
    |> tap(fn arg -> IO.inspect(arg) end)
    |> execute
  end

  def reply_command(arg) do
    IO.puts("IN REPLY COMMAND")
    IO.inspect(arg)
  end

  # User: /pay
  # Bot: "Amount:" reply with force_reply https://core.telegram.org/bots/api#forcereply
  # User: "10 EUR"
  # Bot: "Split:" reply with inline keyboard: 100%, 50%, custom
  # When custom, bot answers: "Custom amount in percent:" reply with force_reply
  # Bot: "Payment was created ..."

  def parse({
        _,
        %Nadia.Model.Update{
          message: %{
            message_id: message_id,
            chat: %{id: chat_id}
          }
        }
      }) do
    {:start, {chat_id, message_id}}
  end

  def execute(
        {:start,
         {
           chat_id,
           message_id
         }}
      ) do
    Nadia.send_message(chat_id, "Amount",
      reply_to_message_id: message_id,
      reply_markup: %{
        force_reply: true,
        input_field_placeholder: "100.00 EUR",
        selective: true
      }
    )
    |> case do
      {:ok, %{message_id: message_id}} ->
        MessageContextStore.set_value(message_id, __MODULE__, :amount)

      nil ->
        nil
    end
  end
end
