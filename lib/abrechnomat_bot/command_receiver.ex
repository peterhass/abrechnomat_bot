defmodule AbrechnomatBot.CommandReceiver do
  require Logger
  use Task
  use GenServer

  defmodule ServerImpl do
    alias Telegex.Type.Update
    alias AbrechnomatBot.TaskPool

    def init do
      %{last_update_id: nil, pool: TaskPool.init()}
    end

    def poll_updates(%{last_update_id: last_update_id, pool: pool} = state) do
      updates_offset =
        last_update_id
        |> case do
          nil -> nil
          id -> id + 1
        end

      {:ok, updates} = Telegex.get_updates(offset: updates_offset)

      {newest_update_id, new_pool} = queue_updates(updates, pool)
      {:ok, %{state | last_update_id: newest_update_id || last_update_id, pool: new_pool}}
    end

    def queue_updates(updates, pool) do
      Enum.reduce(
        updates,
        {nil, pool},
        fn update, {_, acc_pool} ->
          queued_pool_fn = fn -> process_update(update) end

          {update.update_id, TaskPool.run_or_queue(acc_pool, queued_pool_fn)}
        end
      )
    end

    def task_exited(%{pool: pool} = state, pid) do
      new_pool = TaskPool.run_queued_tasks(pool, {:replace, pid})
      %{state | pool: new_pool}
    end

    def process_update(%Update{update_id: update_id} = update) do
      Logger.debug(fn ->
        {"[#{__MODULE__}] Process update: #{inspect(update, pretty: true)}",
         [update_id: update_id]}
      end)

      try do
        AbrechnomatBot.Commands.process_update(update)
      rescue
        err ->
          Logger.log(
            :error,
            "[#{__MODULE__}] Failed at processing update #{update_id}: #{Exception.format(:error, err)}`"
          )

          Logger.log(:debug, inspect(update, pretty: true))
          Logger.log(:debug, Exception.format(:error, err, __STACKTRACE__))
      end

      {:ok, update_id}
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

  @impl true
  def handle_info({_ref, {:ok, _}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_state = ServerImpl.task_exited(state, pid)

    {:noreply, new_state}
  end

  defp schedule_poll() do
    Process.send_after(self(), :poll, 1_000)
  end
end
