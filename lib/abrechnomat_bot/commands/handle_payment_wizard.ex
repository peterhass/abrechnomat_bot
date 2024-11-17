defmodule AbrechnomatBot.Commands.HandlePaymentWizard do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Commands.MessageContextStore

  defmodule ReplyContext do
    defstruct step: nil, origin_message_id: nil, amount: nil
  end

  def command(
        {_,
         %Nadia.Model.Update{
           message: %{
             message_id: message_id,
             chat: %{id: chat_id}
           }
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

    reply_context = %ReplyContext{origin_message_id: message_id, step: :amount}
    MessageContextStore.set_value(response_message_id, __MODULE__, reply_context)
  end

  def reply_command(
        {%ReplyContext{step: :amount} = reply_context,
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
      %ReplyContext{reply_context | step: :split_choice, amount: text}
    )
  end

  def reply_command(
        {%ReplyContext{step: :split_choice, amount: amount, origin_message_id: origin_message_id},
         %Nadia.Model.Update{
           callback_query: %{
             data: "zero",
             message: %{
               chat: %{id: chat_id},
               message_id: message_id
             }
           }
         }}
      ) do
    Nadia.delete_message(chat_id, message_id)

    # TODO: do the work
    Nadia.send_message(chat_id, "Amount: #{amount}, Split: 0%",
      reply_to_message_id: origin_message_id
    )
  end

  def reply_command(
        {%ReplyContext{step: :split_choice, amount: amount, origin_message_id: origin_message_id},
         %Nadia.Model.Update{
           callback_query: %{
             data: "fifty",
             message: %{
               chat: %{id: chat_id},
               message_id: message_id
             }
           }
         }}
      ) do
    Nadia.delete_message(chat_id, message_id)

    # TODO: do the work
    Nadia.send_message(chat_id, "Amount: #{amount}, Split: 50%",
      reply_to_message_id: origin_message_id
    )
  end

  def reply_command(
        {%ReplyContext{step: :split_choice, origin_message_id: origin_message_id} = reply_context,
         %Nadia.Model.Update{
           callback_query: %{
             data: "custom",
             message: %{
               chat: %{id: chat_id},
               message_id: message_id
             }
           }
         }}
      ) do
    Nadia.delete_message(chat_id, message_id)

    {:ok, %{message_id: response_message_id}} =
      Nadia.send_message(chat_id, "Split",
        reply_to_message_id: origin_message_id,
        reply_markup: %{
          force_reply: true,
          input_field_placeholder: "33.3%",
          selective: true
        }
      )

    MessageContextStore.set_value(
      response_message_id,
      __MODULE__,
      %ReplyContext{reply_context | step: :custom_split}
    )
  end

  def reply_command(
        {%ReplyContext{
           step: :custom_split,
           amount: amount,
           origin_message_id: original_message_id
         },
         %Nadia.Model.Update{
           message: %{
             chat: %{id: chat_id},
             text: text
           }
         }}
      ) do
    # TODO: do the actual work here!!
    Nadia.send_message(chat_id, "Amount: #{amount}, Split: #{text}",
      reply_to_message_id: original_message_id
    )
  end
end
