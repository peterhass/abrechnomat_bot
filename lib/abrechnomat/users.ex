defmodule Abrechnomat.Users do
  def to_short_string(%{ username: username }) when not is_nil(username) do
    "@#{username}"
  end

  def to_short_string(%{ first_name: first_name }) when not is_nil(first_name) do
    first_name
  end

  def to_short_string(%{ id: id }) do
    "ID: #{id}"
  end
end