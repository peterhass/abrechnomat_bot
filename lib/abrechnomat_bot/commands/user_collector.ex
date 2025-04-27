# Collect and update as many user information as possible
# Needed for proper username -> id resolve
defmodule AbrechnomatBot.Commands.UserCollector do
  require Logger
  require Amnesia
  require Amnesia.Helper
  alias Telegex.Type.Update
  alias AbrechnomatBot.Database.User

  def process(update) do
    update
    |> collect_users
    |> merge_users
    |> insert_or_update_database
  end

  def insert_or_update_database(users) do
    # TODO: improve performance

    Logger.debug(fn ->
      "[#{__MODULE__}] Update users: #{inspect(users, pretty: true)}"
    end)

    Amnesia.transaction do
      users
      # attributes need to stay the same
      |> Enum.map(&struct(User, Map.from_struct(&1)))
      |> Enum.each(&User.write/1)
    end
  end

  def merge_users(users) do
    reducer = fn user, acc ->
      merged_user =
        Map.merge(
          user,
          Map.get(acc, user.id, %{})
        )

      Map.put(acc, user.id, merged_user)
    end

    Enum.reduce(users, %{}, reducer)
    |> Map.values()
  end

  def collect_users(%Update{message: %{from: nil}} = update) do
    collect_users(delete_in(update, [:message, :from]))
  end

  def collect_users(%Update{message: %{from: user}} = update) do
    [user | collect_users(delete_in(update, [:message, :from]))]
  end

  def collect_users(%Update{message: %{entities: nil}} = update) do
    collect_users(delete_in(update, [:message, :entities]))
  end

  def collect_users(%Update{message: %{entities: entities}} = update) do
    reducer = fn entity, acc ->
      case entity do
        %{type: "text_mention", user: %Telegex.Type.User{} = user} -> [user | acc]
        # TODO: check if still needed after migration to Telegex
        %{type: "text_mention", user: user} -> [struct(Telegex.Type.User, user) | acc]
        _ -> acc
      end
    end

    Enum.reduce(entities, [], reducer) ++ collect_users(delete_in(update, [:message, :entities]))
  end

  def collect_users(_) do
    []
  end

  defp delete_in(data, attribute_path) do
    path = Enum.map(attribute_path, &Access.key!/1)

    {_, new_data} = pop_in(data, path)

    new_data
  end
end
