defmodule AbrechnomatBot.Commands do
  import AbrechnomatBot.Commands.Helpers

  alias __MODULE__.{
    HandlePayment,
    RevertPayment,
    BillStats,
    ExportPayments,
    CloseBill,
    MigrateChat
  }

  defcommand(HandlePayment, "/add_payment")
  defcommand(RevertPayment, "/revert_payment")
  defcommand(BillStats, "/bill_stats")
  defcommand(CloseBill, "/close_bill")
  defcallback(CloseBill, "/close_bill")
  defcommand(ExportPayments, "/export_payments")

  def command(%Nadia.Model.Update{} = update) do
    preprocess_update(update)
    MigrateChat.process(update)

    {:error, :noop}
  end
end
