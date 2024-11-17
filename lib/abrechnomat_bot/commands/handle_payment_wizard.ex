defmodule AbrechnomatBot.Commands.HandlePaymentWizard do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Commands.MessageContextStore
  alias AbrechnomatBot.Commands.HandlePaymentWizard.Parser

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
    text
    |> Parser.parse_amount()
    |> case do
      :error ->
        {:ok, %{message_id: response_message_id}} =
          Nadia.send_message(chat_id, "Unable to parse the provided amount. Try again",
            reply_to_message_id: message_id,
            reply_markup: %{
              force_reply: true,
              input_field_placeholder: "100.00 EUR",
              selective: true
            }
          )

        reply_context = %ReplyContext{reply_context | step: :amount}
        MessageContextStore.set_value(response_message_id, __MODULE__, reply_context)

      {:ok, money} ->
        {:ok, %{message_id: response_message_id}} =
          Nadia.send_message(chat_id, "Own share",
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

        reply_context = %ReplyContext{reply_context | step: :split_choice, amount: money}
        MessageContextStore.set_value(response_message_id, __MODULE__, reply_context)
    end
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
      Nadia.send_message(chat_id, "Own share",
        reply_to_message_id: origin_message_id,
        reply_markup: %{
          force_reply: true,
          input_field_placeholder: "33%",
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
           origin_message_id: origin_message_id
         } = reply_context,
         %Nadia.Model.Update{
           message: %{
             chat: %{id: chat_id},
             message_id: message_id,
             text: text
           }
         }}
      ) do
    text
    |> Parser.parse_share()
    |> case do
      :error ->
        {:ok, %{message_id: response_message_id}} =
          Nadia.send_message(
            chat_id,
            "Unable to parse the provided share. Shares cannot have fractions. Try again",
            reply_to_message_id: message_id,
            reply_markup: %{
              force_reply: true,
              input_field_placeholder: "33%",
              selective: true
            }
          )

        MessageContextStore.set_value(
          response_message_id,
          __MODULE__,
          %ReplyContext{reply_context | step: :custom_split}
        )

      {:ok, own_share} ->
        # TODO: do the actual work here!!
        Nadia.send_message(chat_id, "Amount: #{amount}, Own Share: #{own_share}",
          reply_to_message_id: origin_message_id
        )
    end
  end
end
