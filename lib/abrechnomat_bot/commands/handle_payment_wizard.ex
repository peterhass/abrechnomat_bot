defmodule AbrechnomatBot.Commands.HandlePaymentWizard do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment, User}
  alias AbrechnomatBot.Commands.MessageContextStore
  alias AbrechnomatBot.Commands.HandlePaymentWizard.Parser
  import Phoenix.HTML

  defmodule ReplyContext do
    defstruct step: nil,
              chat_id: nil,
              origin_message_id: nil,
              amount: nil,
              own_share: nil,
              text: nil,
              date: nil
  end

  def command(
        {_,
         %Nadia.Model.Update{
           message: %{
             message_id: message_id,
             chat: %{id: chat_id},
             date: date
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

    reply_context = %ReplyContext{
      chat_id: chat_id,
      origin_message_id: message_id,
      step: :amount,
      date: DateTime.from_unix!(date)
    }

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
        {%ReplyContext{step: :split_choice} = reply_context,
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

    ask_for_text!(%ReplyContext{reply_context | own_share: 0.0})
  end

  def reply_command(
        {%ReplyContext{step: :split_choice} = reply_context,
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

    ask_for_text!(%ReplyContext{reply_context | own_share: 0.5})
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
           step: :custom_split
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
        ask_for_text!(%ReplyContext{reply_context | own_share: own_share})
    end
  end

  def reply_command(
        {%ReplyContext{
           step: :text
         } = reply_context,
         %Nadia.Model.Update{
           message: %{
             chat: %{id: chat_id},
             message_id: message_id,
             text: text,
             from: from_user
           }
         }}
      ) do
    text
    |> Parser.parse_text()
    |> case do
      {:error, _} ->
        {:ok, %{message_id: response_message_id}} =
          Nadia.send_message(
            chat_id,
            "Unable to parse the provided text. Try again",
            reply_to_message_id: message_id,
            reply_markup: %{
              force_reply: true,
              input_field_placeholder: "Pizza",
              selective: true
            }
          )

        MessageContextStore.set_value(
          response_message_id,
          __MODULE__,
          reply_context
        )

      {:ok, text} ->
        %ReplyContext{reply_context | text: text}
        |> create_payment_and_reply(from_user)
    end
  end

  defp ask_for_text!(
         %ReplyContext{chat_id: chat_id, origin_message_id: origin_message_id} = reply_context
       ) do
    {:ok, %{message_id: response_message_id}} =
      Nadia.send_message(chat_id, "Nature of the expenditure",
        reply_to_message_id: origin_message_id,
        reply_markup: %{
          force_reply: true,
          input_field_placeholder: "Pizza",
          selective: true
        }
      )

    MessageContextStore.set_value(
      response_message_id,
      __MODULE__,
      %ReplyContext{reply_context | step: :text}
    )
  end

  defp create_payment_and_reply(
         %ReplyContext{
           chat_id: chat_id,
           origin_message_id: message_id,
           amount: amount,
           own_share: own_share,
           text: text,
           date: date
         },
         nadia_user
       ) do
    Amnesia.transaction do
      Bill.find_or_create_by_chat(chat_id)
      |> Bill.add_payment(full_user_resolve(nadia_user), date, amount, own_share, text)
      |> payment_message
      |> send_success_message(chat_id, message_id)
    end
  end

  defp full_user_resolve(%{id: id}) do
    User.find(id)
  end

  defp send_success_message(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "HTML")
  end

  defp payment_message(
         %Payment{id: id, user: user, date: date, amount: amount, text: text} = payment
       ) do
    [
      "Added following payment ...",
      "ID: #{id}",
      Abrechnomat.Users.to_short_string(user),
      "#{date}",
      "#{amount}",
      payment_message_share(payment),
      "Text: #{text}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> html_escape
    |> safe_to_string
  end

  # TODO: still needed? we always provide own_share value
  #   Update: Yes, needed for groups with growing users(?) (DOUBLE CHECK!)
  defp payment_message_share(%Payment{amount: _, own_share: own_share}) when is_nil(own_share) do
    nil
  end

  defp payment_message_share(%Payment{amount: amount, own_share: own_share}) do
    "own share: #{own_share}% = #{Money.multiply(amount, own_share)}"
  end
end
