defmodule AbrechnomatBot.Commands.MigrateChat do
  require Amnesia
  require Amnesia.Helper
  alias AbrechnomatBot.Database.Bill

  def process(update) do
    update
    |> parse
    |> execute
  end

  def parse(%Nadia.Model.Update{
        message: %{migrate_from_chat_id: old_chat_id, chat: %{id: new_chat_id}}
      }) do
    {:ok, {old_chat_id, new_chat_id}}
  end

  def parse(%Nadia.Model.Update{
        message: %{chat: %{id: old_chat_id}, migrate_to_chat_id: new_chat_id}
      }) do
    {:ok, {old_chat_id, new_chat_id}}
  end

  def parse(_) do
    {:error}
  end

  def execute({:ok, {old_chat_id, new_chat_id}}) do
    Amnesia.transaction do
      migrate_chat(Bill.find_by_chat(old_chat_id), new_chat_id)
    end
  end

  def execute({:error}) do
    {:noop, "No action required"}
  end

  defp migrate_chat(nil, new_chat_id) do
    {:noop, "No bill registered for given chat id"}
  end

  defp migrate_chat(old_chat, new_chat_id) do
    %{old_chat | chat_id: new_chat_id}
    |> Bill.write()

    {:ok, new_chat_id}
  end
end
