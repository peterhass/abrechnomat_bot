defmodule Abrechnomat.Times do
  @doc """
    returns milliseconds
  """
  def seconds(sec) do
    sec * 1000
  end

  @doc """
    returns milliseconds
  """
  def minutes(min) do
    seconds(60 * min)
  end
end
