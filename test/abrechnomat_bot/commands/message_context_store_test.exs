defmodule AbrechnomatBot.Commands.MessageContextStoreTest do
  use ExUnit.Case, async: true
  alias AbrechnomatBot.Commands.MessageContextStore

  setup do
    MessageContextStore.start_link()
    :ok
  end

  test "stores contexts by message" do
    assert MessageContextStore.get_context(1) == nil
    MessageContextStore.set_value(1, __MODULE__, %{my_context: true})

    assert MessageContextStore.get_context(1) == {__MODULE__, %{my_context: true}}

    assert MessageContextStore.get_context(2) == nil
    MessageContextStore.set_value(2, __MODULE__, %{my_context: true}, 200)

    assert MessageContextStore.get_context(2) == {__MODULE__, %{my_context: true}}
  end

  test "drops context after ttl" do
    assert MessageContextStore.get_context(1) == nil

    MessageContextStore.set_value(1, __MODULE__, %{my_context: true}, 200)
    assert MessageContextStore.get_context(1) == {__MODULE__, %{my_context: true}}

    :timer.sleep(200)
    assert MessageContextStore.get_context(1) == nil
  end
end
