defmodule AbrechnomatBot.CommandReceiver do
  require Logger
  use Task
  use GenServer

  defmodule ServerImpl do
    def init do
      %{last_update_id: nil}
    end

    def poll_updates(%{last_update_id: last_update_id} = state) do
      updates_offset =
        last_update_id
        |> case do
          nil -> nil
          id -> id + 1
        end

      {:ok, updates} = Nadia.get_updates(offset: updates_offset)

      if updates == [] do
        {:ok, state}
      else
        {:ok, newest_update_id} = process_updates(updates)
        {:ok, %{state | last_update_id: newest_update_id}}
      end
    end

    def process_updates(updates) do
      updates
      |> List.pop_at(0)
      |> _process_updates
    end

    defp _process_updates({update, remaining_updates}) when remaining_updates == [] do
      process_update(update)
    end

    defp _process_updates({update, remaining_updates}) do
      {:ok, _update_id} = process_update(update)

      process_updates(remaining_updates)
    end

    def process_update(%{update_id: update_id} = update) do
      Logger.debug(fn ->
        {"[#{__MODULE__}] Process update: #{inspect(update)}", [update_id: update_id]}
      end)

      AbrechnomatBot.CommandReceiver.Parser.parse(update)
      |> case do
        {:ok, :handle_payment, blubb} ->
          Logger.debug(inspect(blubb))
        _ ->
          nil
      end


      #DienerHansBot.CommandReceiver.Parser.parse_update(update)
      #|> case do
      #  {:ok, :schedule_reminder, reminder} ->
      #    DienerHansBot.ReminderClock.schedule_reminder(reminder)

      #  _ ->
      #    nil
      #end

      {:ok, update_id}
    end
  end

  # client
  def start_link do
    GenServer.start_link(__MODULE__, ServerImpl.init(), name: __MODULE__)
  end

  # server callbacks
  @impl true
  def init(state) do
    schedule_poll()
    {:ok, state}
  end

  @impl true
  def handle_info(:poll, state) do
    {:ok, new_state} = ServerImpl.poll_updates(state)

    schedule_poll()
    {:noreply, new_state}
  end

  defp schedule_poll() do
    Process.send_after(self(), :poll, 1_000)
  end
end
