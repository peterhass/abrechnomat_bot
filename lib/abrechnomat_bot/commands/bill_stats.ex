defmodule AbrechnomatBot.Commands.BillStats do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment}

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
          payments = Payment.by_bill(bill_id)

          user_sums = Abrechnomat.Billing.sums_by_user(payments)
          user_balances = Abrechnomat.Billing.balances_by_user(user_sums)

          transaction_message =
            Abrechnomat.Billing.transactions(user_balances)
            |> Enum.map(&transaction_text/1)
            |> Enum.join("\n")

          # FIXME: may not make sense for the user
          sums_message =
            user_sums
            |> Enum.map(&user_sum_text/1)
            |> Enum.join("\n")

          [sums_message, transaction_message]
          |> Enum.join("\n\n")
          |> reply(chat_id, message_id)
      end
    end
  end

  defp parse({_, %Nadia.Model.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}) do
    {chat_id, message_id}
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id)
  end

  defp user_sum_text({username, amount}) do
    "@#{username}: #{amount}"
  end

  defp transaction_text({from_user, to_user, amount}) do
    "@#{from_user} -> @#{to_user} : #{amount}"
  end
end
