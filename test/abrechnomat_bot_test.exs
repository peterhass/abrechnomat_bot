defmodule AbrechnomatBotTest do
  use ExUnit.Case
  doctest AbrechnomatBot

  test "greets the world" do
    assert AbrechnomatBot.hello() == :world
  end
end
