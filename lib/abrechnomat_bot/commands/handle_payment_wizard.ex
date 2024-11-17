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
        reply_markup: %Nadia.Model.InlineKeyboardMarkup{
          inline_keyboard: [
            [
              %{callback_data: "zero", text: "0%"},
              %{callback_data: "fifty", text: "50%"},
              %{callback_data: "custom", text: "Custom"}
            ]
          ]
        }
      )

    MessageContextStore.set_value(
      response_message_id,
      __MODULE__,
      {:split_choice, %{amount: text}}
    )
  end

  def reply_command(
        {{:split_choice, %{amount: amount}},
         %Nadia.Model.Update{
           callback_query: %{
             data: "zero",
             message: %{
               message_id: message_id,
               chat: %{id: chat_id}
             }
           }
         }}
      ) do
    # TODO: do the work
    Nadia.send_message(chat_id, "Amount: #{amount}, Split: 0%", reply_to_message_id: message_id)
  end

  def reply_command(
        {{:split_choice, %{amount: amount}},
         %Nadia.Model.Update{
           callback_query: %{
             data: "fifty",
             message: %{
               message_id: message_id,
               chat: %{id: chat_id}
             }
           }
         }}
      ) do
    # TODO: do the work
    Nadia.send_message(chat_id, "Amount: #{amount}, Split: 50%", reply_to_message_id: message_id)
  end

  def reply_command(
        {{:split_choice, %{amount: amount}},
         %Nadia.Model.Update{
           callback_query: %{
             data: "custom",
             message: %{
               message_id: message_id,
               chat: %{id: chat_id}
             }
           }
         }}
      ) do
    {:ok, %{message_id: response_message_id}} =
      Nadia.send_message(chat_id, "Split",
        reply_to_message_id: message_id,
        reply_markup: %{
          force_reply: true,
          input_field_placeholder: "33.3%",
          selective: true
        }
      )

    MessageContextStore.set_value(
      response_message_id,
      __MODULE__,
      {:custom_split, %{amount: amount}}
    )
  end

  def reply_command(
        {{:custom_split, %{amount: amount}},
         %Nadia.Model.Update{
           message: %{
             message_id: message_id,
             chat: %{id: chat_id},
             text: text
           }
         }}
      ) do
    # TODO: do the actual work here!!
    Nadia.send_message(chat_id, "Amount: #{amount}, Split: #{text}",
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
