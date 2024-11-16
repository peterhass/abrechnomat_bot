defmodule AbrechnomatBot.Commands.MessageContextStore do
  use Agent

  defmodule StoreImpl do
    def init do
      %{}
    end

    # TODO: implement ttl logic
    def set(state, message_id, module, value) do
      state
      |> Map.put(message_id, {module, value})
    end

    def get(state, message_id) do
      state[message_id]
    end
  end

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def start_link do
    start_link(StoreImpl.init())
  end

  def set_value(message_id, module, value) do
    Agent.update(__MODULE__, &(StoreImpl.set(&1, message_id, module, value)))
  end

  def get_context(message_id) do
    Agent.get(__MODULE__, &(StoreImpl.get(&1, message_id)))
  end
end
