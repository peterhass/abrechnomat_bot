defmodule AbrechnomatBot.Commands do
  import AbrechnomatBot.Commands.Helpers

  alias __MODULE__.{
    HandlePayment,
    RevertPayment,
    BillStats,
    ExportPayments,
    CloseBill
  }

  #  {
  # "description": "Bad Request: group chat was upgraded to a supergroup chat",
  # "error_code": 400,
  # "ok": false,
  #   "parameters": {
  #   "migrate_to_chat_id": -1001477607310
  #   }
  #   }
  # TODO: handle "migrate_to_chat_id"

  defcommand(HandlePayment, "/add_payment")
  defcommand(RevertPayment, "/revert_payment")
  defcommand(BillStats, "/bill_stats")
  defcommand(CloseBill, "/close_bill")
  defcallback(CloseBill, "/close_bill")
  defcommand(ExportPayments, "/export_payments")

  def command(%Nadia.Model.Update{} = update) do
    preprocess_update(update)
    {:error, :noop}
  end
end
