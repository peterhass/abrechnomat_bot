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
    MigrateChat,
    SetLocale,
  }

  defcommand(HandlePayment, "/add_payment")
  defcommand(HandlePaymentWizard, "/pay")
  defreply(HandlePaymentWizard)
  defcommand(RevertPayment, "/revert_payment")
  defcommand(BillStats, "/bill_stats")
  defcommand(CloseBill, "/close_bill")
  defcallback(CloseBill, "/close_bill")
  defcommand(ExportPayments, "/export_payments")
  defcommand(SetLocale, "/set_locale")

  def process_update(update) do
    preprocess_update(update)
    {process_reply(update), command(update)}
  end

  def command(%Telegex.Type.Update{} = update) do
    MigrateChat.process(update)

    {:error, :noop}
  end

  defp process_reply(
         %Telegex.Type.Update{message: %{reply_to_message: %{message_id: reply_to_message_id}}} =
           update
       ) do
    context = MessageContextStore.get_context(reply_to_message_id)
    reply(context, update)
  end

  defp process_reply(
         %Telegex.Type.Update{
           callback_query: %{message: %{message_id: reply_to_message_id}}
         } =
           update
       ) do
    context = MessageContextStore.get_context(reply_to_message_id)
    reply(context, update)
  end

  defp process_reply(_), do: {:error, :noop}

  defp reply(nil, _), do: {:error, :noop}

  defp reply(_, _), do: {:error, :noop}
end
