defmodule AbrechnomatBot.UpdateQueue do
  require Logger
  use Task
  use GenServer

  defmodule ServerImpl do
    alias Telegex.Type.Update
    alias AbrechnomatBot.TaskPool

    def init do
      %{pool: TaskPool.init()}
    end

    def queue_update(%{pool: pool} = state, update) do
      queued_pool_fn = fn -> process_update(update) end

      {:ok, %{state | pool: TaskPool.run_or_queue(pool, queued_pool_fn)}}
    end

    def task_exited(%{pool: pool} = state, pid) do
      new_pool = TaskPool.run_queued_tasks(pool, {:replace, pid})
      %{state | pool: new_pool}
    end

    defp process_update(%Update{update_id: update_id} = update) do
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

  def queue(update) do
    GenServer.cast(__MODULE__, {:queue, update})
  end

  # server callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:queue, update}, state) do
    {:ok, new_state} = ServerImpl.queue_update(state, update)
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
end
