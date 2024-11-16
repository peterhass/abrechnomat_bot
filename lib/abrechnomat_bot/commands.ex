defmodule AbrechnomatBot.Commands do
  import AbrechnomatBot.Commands.Helpers
  alias AbrechnomatBot.Commands.MessageContextStore

  alias __MODULE__.{
    HandlePayment,
    HandlePaymentWizard,
    RevertPayment,
    BillStats,
    ExportPayments,
    CloseBill,
    MigrateChat
  }

  defcommand(HandlePayment, "/add_payment")
  defcommand(HandlePaymentWizard, "/pay")
  defreply(HandlePaymentWizard)
  defcommand(RevertPayment, "/revert_payment")
  defcommand(BillStats, "/bill_stats")
  defcommand(CloseBill, "/close_bill")
  defcallback(CloseBill, "/close_bill")
  defcommand(ExportPayments, "/export_payments")

  def process_update(update) do
    preprocess_update(update)
    {process_reply(update), command(update)}
  end

  def command(%Nadia.Model.Update{} = update) do
    MigrateChat.process(update)

    {:error, :noop}
  end

  defp process_reply(
         %Nadia.Model.Update{message: %{reply_to_message: %{message_id: reply_to_message_id}}} =
           update
       ) do
    context = MessageContextStore.get_context(reply_to_message_id)
    reply(context, update)
  end

  defp process_reply(_), do: {:error, :noop}

  defp reply(nil, _), do: {:error, :noop}
  defp reply(_, _), do: {:error, :noop}
end
