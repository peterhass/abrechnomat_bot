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

  def reply_command(
        {:amount,
         %Nadia.Model.Update{
           message: %{
             message_id: message_id,
             chat: %{id: chat_id},
             text: text
           }
         }}
      ) do
    {:ok, %{message_id: response_message_id}} =
      Nadia.send_message(chat_id, "Split",
        reply_to_message_id: message_id,
        reply_markup: %{
          force_reply: true,
          input_field_placeholder: "50%",
          selective: true
        }
      )

    # TODO: needs proper parsing!

    # TODO: add custom keyboards!
    #   Bot: "Split:" reply with inline keyboard: 100%, 50%, custom
    #   When custom, bot answers: "Custom amount in percent:" reply with force_reply

    MessageContextStore.set_value(response_message_id, __MODULE__, {:split, %{amount: text}})
  end

  def reply_command(
        {{:split, %{amount: amount}},
         %Nadia.Model.Update{
           message: %{
             message_id: message_id,
             chat: %{id: chat_id},
             text: text
           }
         }}
      ) do

    # TODO: do the actual work here!!
    Nadia.send_message(chat_id, "Created! #{amount} with split #{text}",
      reply_to_message_id: message_id
    )
  end

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
    {:ok, %{message_id: response_message_id}} =
      Nadia.send_message(chat_id, "Amount",
        reply_to_message_id: message_id,
        reply_markup: %{
          force_reply: true,
          input_field_placeholder: "100.00 EUR",
          selective: true
        }
      )

    MessageContextStore.set_value(response_message_id, __MODULE__, :amount)
  end
end
