defmodule AbrechnomatBot.Commands.MessageContextStoreTest do
  use ExUnit.Case, async: true
  alias AbrechnomatBot.Commands.MessageContextStore

  test "stores contexts by message", %{test: test_name} do
    pid = start_supervised!({MessageContextStore, [name: test_name]})

    assert MessageContextStore.get_context(1, pid: pid) == nil
    MessageContextStore.set_value(1, __MODULE__, %{my_context: true}, ttl: 30, pid: pid)

    assert MessageContextStore.get_context(1, pid: pid) == {__MODULE__, %{my_context: true}}

    assert MessageContextStore.get_context(2, pid: pid) == nil
    MessageContextStore.set_value(2, __MODULE__, %{my_context: true}, ttl: 30, pid: pid)

    assert MessageContextStore.get_context(2, pid: pid) == {__MODULE__, %{my_context: true}}
  end

  test "drops context after ttl", %{test: test_name} do
    pid = start_supervised!({MessageContextStore, [name: test_name]})

    assert MessageContextStore.get_context(2, pid: pid) == nil

    MessageContextStore.set_value(2, __MODULE__, %{my_context: true}, ttl: 20, pid: pid)
    assert MessageContextStore.get_context(2, pid: pid) == {__MODULE__, %{my_context: true}}

    :timer.sleep(40)
    assert MessageContextStore.get_context(2, pid: pid) == nil
  end
end
