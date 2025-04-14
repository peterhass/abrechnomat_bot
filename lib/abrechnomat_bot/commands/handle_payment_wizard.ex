defmodule AbrechnomatBot.Commands.HandlePaymentWizard do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Chat, Bill, Payment, User}
  alias AbrechnomatBot.Commands.MessageContextStore
  alias AbrechnomatBot.Commands.HandlePaymentWizard.Parser
  alias AbrechnomatBot.I18n
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
         %Telegex.Type.Update{
           message: %{
             message_id: message_id,
             chat: %{id: chat_id},
             date: date
           }
         }}
      ) do
    i18n = chat_i18n(chat_id, new_transaction: true)

    {:ok, %{message_id: response_message_id}} =
      Telegex.send_message(
        chat_id,
        "🎉 Hey hey! Ready to split a bill? ✌️ How much are we talking here? 💸",
        reply_to_message_id: message_id,
        reply_markup: %{
          force_reply: true,
          input_field_placeholder: Money.new(10000, :EUR) |> I18n.money!(i18n),
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
         %Telegex.Type.Update{
           message: %{
             message_id: message_id,
             chat: %{id: chat_id},
             text: text
           }
         }}
      ) do
    i18n = chat_i18n(chat_id, new_transaction: true)

    text
    |> Parser.parse_amount(i18n)
    |> case do
      :error ->
        {:ok, %{message_id: response_message_id}} =
          Telegex.send_message(chat_id, "Unable to parse the provided amount. Try again",
            reply_to_message_id: message_id,
            reply_markup: %{
              force_reply: true,
              input_field_placeholder: Money.new(10000, :EUR) |> I18n.money!(i18n),
              selective: true
            }
          )

        reply_context = %ReplyContext{reply_context | step: :amount}

        MessageContextStore.set_value(response_message_id, __MODULE__, reply_context)

      {:ok, money} ->
        {:ok, %{message_id: response_message_id}} =
          Telegex.send_message(
            chat_id,
            "💰 Big spender! Okay, how are we dividing this treasure? 🪙 (How big is your part of the bill?)",
            reply_to_message_id: message_id,
            reply_markup: %Telegex.Type.InlineKeyboardMarkup{
              inline_keyboard: [
                [
                  %{callback_data: "group-equal", text: "Equally distributed over whole group"},
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
         %Telegex.Type.Update{
           callback_query: %{
             data: "group-equal",
             message: %{
               chat: %{id: chat_id},
               message_id: message_id
             }
           }
         }}
      ) do
    Telegex.delete_message(chat_id, message_id)

    ask_for_text!(%ReplyContext{reply_context | own_share: nil})
  end

  def reply_command(
        {%ReplyContext{step: :split_choice} = reply_context,
         %Telegex.Type.Update{
           callback_query: %{
             data: "zero",
             message: %{
               chat: %{id: chat_id},
               message_id: message_id
             }
           }
         }}
      ) do
    Telegex.delete_message(chat_id, message_id)

    ask_for_text!(%ReplyContext{reply_context | own_share: 0.0})
  end

  def reply_command(
        {%ReplyContext{step: :split_choice} = reply_context,
         %Telegex.Type.Update{
           callback_query: %{
             data: "fifty",
             message: %{
               chat: %{id: chat_id},
               message_id: message_id
             }
           }
         }}
      ) do
    Telegex.delete_message(chat_id, message_id)

    ask_for_text!(%ReplyContext{reply_context | own_share: 0.5})
  end

  def reply_command(
        {%ReplyContext{step: :split_choice, origin_message_id: origin_message_id} = reply_context,
         %Telegex.Type.Update{
           callback_query: %{
             data: "custom",
             message: %{
               chat: %{id: chat_id},
               message_id: message_id
             }
           }
         }}
      ) do
    Telegex.delete_message(chat_id, message_id)

    {:ok, %{message_id: response_message_id}} =
      Telegex.send_message(chat_id, "Own share",
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
         %Telegex.Type.Update{
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
          Telegex.send_message(
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
         %Telegex.Type.Update{
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
          Telegex.send_message(
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
      Telegex.send_message(
        chat_id,
        "Easy peasy. 🍋 What’s this cash for? 🎯 (e.g., dinner 🍕, groceries 🛒, trip ✈️, or something wild 🦄?)",
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
      i18n = chat_i18n(chat_id)

      Bill.find_or_create_by_chat(chat_id)
      |> Bill.add_payment(full_user_resolve(nadia_user), date, amount, own_share, text)
      |> payment_message(i18n)
      |> send_success_message(chat_id, message_id)
    end
  end

  defp full_user_resolve(%{id: id}) do
    User.find(id)
  end

  defp send_success_message(text, chat_id, message_id) do
    Telegex.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "HTML")
  end

  defp payment_message(
         %Payment{id: id, user: user, date: date, amount: amount, text: text} = payment,
         i18n
       ) do
    [
      "🎉 Ka-ching! Payment added! 💸",
      "ID: #{id}",
      Abrechnomat.Users.to_short_string(user),
      "#{I18n.datetime!(date, i18n)}",
      "#{I18n.money!(amount, i18n)}",
      payment_message_share(payment, i18n),
      "Text: #{text}"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> html_escape
    |> safe_to_string
  end

  # TODO: still needed? we always provide own_share value
  #   Update: Yes, needed for groups with growing users(?) (DOUBLE CHECK!)
  defp payment_message_share(%Payment{amount: _, own_share: own_share}, _i18n)
       when is_nil(own_share) do
    nil
  end

  defp payment_message_share(%Payment{amount: amount, own_share: own_share}, i18n) do
    localized_share_amount =
      Money.multiply(amount, own_share)
      |> I18n.money!(i18n)

    "own share: #{own_share}% = #{localized_share_amount}"
  end

  defp chat_i18n(chat_id, new_transaction: true) do
    Amnesia.transaction do
      chat_i18n(chat_id)
    end
  end

  defp chat_i18n(chat_id) do
    chat_id
    |> Chat.find_or_default()
    |> Chat.i18n()
  end
end
