defmodule AbrechnomatBot.PollingHandler do
  require Logger
  use Task
  use GenServer

  defmodule ServerImpl do
    alias AbrechnomatBot.UpdateQueue

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

      {:ok, updates} = Telegex.get_updates(offset: updates_offset)
      newest_update = List.last(updates)

      if newest_update do
        queue_updates(updates)

        {:ok, %{state | last_update_id: newest_update.update_id || last_update_id}}
      else
        {:ok, state}
      end
    end

    def queue_updates(updates) do
      Enum.each(updates, fn update -> UpdateQueue.queue(update) end)
    end
  end

  # client
  def start_link(_) do
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
