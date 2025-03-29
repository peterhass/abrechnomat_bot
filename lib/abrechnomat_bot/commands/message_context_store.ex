defmodule AbrechnomatBot.Commands.MessageContextStore do
  use GenServer
  alias Abrechnomat.Times

  defmodule StoreImpl do
    def init do
      %{}
    end

    def set(state, message_id, module, value) do
      state
      |> Map.put(message_id, {module, value})
    end

    def get(state, message_id) do
      state[message_id]
    end

    def delete(state, message_id) do
      state
      |> Map.delete(message_id)
    end
  end

  # client
  def start_link(default) when is_list(default) do
    options = Keyword.merge([name: __MODULE__], default)
    GenServer.start_link(__MODULE__, StoreImpl.init(), options)
  end

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, StoreImpl.init(), default)
  end

  def set_value(message_id, module, value, options \\ []) do
    pid = Keyword.get(options, :pid, __MODULE__)
    ttl = Keyword.get(options, :ttl, Times.minutes(10))

    GenServer.call(
      pid,
      {:set_value, message_id, module, value, ttl}
    )
  end

  def get_context(message_id, options \\ []) do
    pid = Keyword.get(options, :pid, __MODULE__)
    GenServer.call(pid, {:get_context, message_id})
  end

  # server
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get_context, message_id}, _from, state) do
    context = StoreImpl.get(state, message_id)

    {:reply, context, state}
  end

  @impl true
  def handle_call({:set_value, message_id, module, value, ttl}, _from, state) do
    new_state = StoreImpl.set(state, message_id, module, value)

    Process.send_after(self(), {:expire, message_id}, ttl)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:expire, message_id}, state) do
    new_state = StoreImpl.delete(state, message_id)

    {:noreply, new_state}
  end
end
