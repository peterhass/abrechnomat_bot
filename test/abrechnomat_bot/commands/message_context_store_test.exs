defmodule AbrechnomatBot.Commands.MessageContextStoreTest do
  # use ExUnit.Case, async: true
  use ExUnit.Case
  alias AbrechnomatBot.Commands.MessageContextStore

  test "stores contexts by message", %{test: test_name} do
    {:ok, store_pid} = start_supervised({MessageContextStore, [name: test_name]})

    assert MessageContextStore.get_context(store_pid, 1) == nil
    MessageContextStore.set_value(store_pid, 1, __MODULE__, %{my_context: true}, ttl: 30)

    assert MessageContextStore.get_context(store_pid, 1) == {__MODULE__, %{my_context: true}}

    assert MessageContextStore.get_context(store_pid, 2) == nil
    MessageContextStore.set_value(store_pid, 2, __MODULE__, %{my_context: true}, ttl: 30)

    assert MessageContextStore.get_context(store_pid, 2) == {__MODULE__, %{my_context: true}}
  end

  test "drops context after ttl", %{test: test_name} do
    {:ok, store_pid} = start_supervised({MessageContextStore, [name: test_name]})

    assert MessageContextStore.get_context(store_pid, 2) == nil

    MessageContextStore.set_value(store_pid, 2, __MODULE__, %{my_context: true}, ttl: 20)
    assert MessageContextStore.get_context(store_pid, 2) == {__MODULE__, %{my_context: true}}

    :timer.sleep(40)
    assert MessageContextStore.get_context(store_pid, 2) == nil
  end
end
