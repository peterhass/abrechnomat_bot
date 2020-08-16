defmodule AbrechnomatBot.Commands do
  alias __MODULE__.{
    HandlePayment, 
    RevertPayment,
    BillStats,
    CloseBill,
    UserCollector
  }

#  {
#"description": "Bad Request: group chat was upgraded to a supergroup chat",
#"error_code": 400,
#"ok": false,
#   "parameters": {
#   "migrate_to_chat_id": -1001477607310
#   }
#   }
  # TODO: handle "migrate_to_chat_id"

  def command(%Nadia.Model.Update{message: %{text: "/add_payment" <> text}} = update) do
    preprocess_update(update)
    HandlePayment.command({text, update})
  end

  def command(%Nadia.Model.Update{message: %{text: "/revert_payment" <> text}} = update) do
    preprocess_update(update)
    RevertPayment.command({text, update})
  end

  def command(%Nadia.Model.Update{message: %{text: "/bill_stats" <> text}} = update) do
    preprocess_update(update)
    BillStats.command({text, update})
  end

  def command(%Nadia.Model.Update{message: %{text: "/close_bill" <> text}} = update) do
    preprocess_update(update)
    CloseBill.command({text, update})
  end

  def command(%Nadia.Model.Update{callback_query: %{data: "/close_bill" <> text}} = update) do
    preprocess_update(update)
    CloseBill.command_callback({text, update})
  end

  def command(%Nadia.Model.Update{} = update) do
    preprocess_update(update)
    {:error, :noop}
  end

  defp preprocess_update(update) do
    UserCollector.process(update)
  end
end
