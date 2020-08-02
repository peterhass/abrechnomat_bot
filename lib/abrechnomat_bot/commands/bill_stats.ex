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
        nil -> reply("No active bill", chat_id, message_id)
        %{id: bill_id} ->
          payments = Payment.by_bill(bill_id)

          payments
          |> Enum.map(&inspect(&1, pretty: true))
          |> Enum.join("\n")
          |> IO.puts

          user_sums = Abrechnomat.Billing.sums_by_user(payments)
          user_balances = Abrechnomat.Billing.balances_by_user(user_sums)

          IO.puts("USER SUMS")
          IO.puts(inspect(user_sums, pretty: true))

          IO.puts("USER BALANCES")
          IO.puts(inspect(user_balances, pretty: true))

          pay_instructions = Abrechnomat.Billing.get_pay_instructions() # ????

          IO.puts("PAY INSTRUCTIONS")
          IO.puts(inspect(pay_instructions, pretty: true))
      end
    end
  end

  defp parse({ _, %Nadia.Model.Update{ message: %{ message_id: message_id, chat: %{ id: chat_id } } } }) do
    {chat_id, message_id}
  end

  defp reply(text, chat_id, message_id) do
    Nadia.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "Markdown")
  end
end

