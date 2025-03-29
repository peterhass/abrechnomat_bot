defmodule AbrechnomatBot.Commands.BillStats do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.{Bill, Payment, User}
  alias Abrechnomat.Billing
  alias Abrechnomat.Users

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

          ast = Billing.payment_to_ast(payments)

          case Billing.user_shares_from_ast(ast) do
            {:error, reason} ->
              shares_error_message(reason)
              |> reply(chat_id, message_id)

            user_shares ->
              user_sums = Billing.user_sums_from_ast(ast)
              user_balances = Billing.balances_by_user(user_sums, user_shares)
              transactions = Billing.transactions(user_balances)

              transaction_message =
                transactions
                |> transactions_with_resolved_users
                |> Enum.map(&transaction_text/1)
                |> Enum.join("\n")

              sums_message =
                user_balances
                |> user_sums_with_resolved_users
                |> Enum.map(&user_sum_text/1)
                |> Enum.join("\n")

              [
                sums_message,
                transaction_message
              ]
              |> Enum.join("\n\n")
              |> reply(chat_id, message_id)
          end
      end
    end
  end

  defp parse({_, %Telegex.Type.Update{message: %{message_id: message_id, chat: %{id: chat_id}}}}) do
    {chat_id, message_id}
  end

  defp reply(text, chat_id, message_id) do
    Telegex.send_message(chat_id, text, reply_to_message_id: message_id)
  end

  defp transactions_with_resolved_users(transactions) do
    Enum.map(transactions, fn {from_user_id, to_user_id, amount} ->
      {User.find(from_user_id), User.find(to_user_id), amount}
    end)
  end

  defp user_sums_with_resolved_users(user_sums) do
    Enum.map(user_sums, fn {user_id, amount} ->
      {User.find(user_id), amount}
    end)
  end

  defp user_sum_text({user, amount}) do
    if Money.positive?(amount) do
      "#{Users.to_short_string(user)} owes #{amount} to the group"
    else
      "the group owes #{Users.to_short_string(user)} #{Money.abs(amount)}"
    end
  end

  defp transaction_text({from_user, to_user, amount}) do
    "#{Users.to_short_string(from_user)} -> #{Users.to_short_string(to_user)} : #{amount}"
  end

  defp shares_error_message(:multiple_users_needed) do
    "Cannot split a bill around one single user. To 'add' users to the bill, add a payment for 0 amount."
  end
end
