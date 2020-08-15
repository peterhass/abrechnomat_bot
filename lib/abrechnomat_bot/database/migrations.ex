defmodule AbrechnomatBot.Database.Migrations do
  alias AbrechnomatBot.Database
  alias AbrechnomatBot.Database.Migration
  require Amnesia
  require Amnesia.Helper

  def run do
    case db_exists?() do
      true ->
        Amnesia.transaction(&Migration.get_current_version/0)
      false -> nil
    end
    |> migration

    :ok
  end

  @most_recent_version "1"

  def migration("initialized") do
    Amnesia.transaction do
      Migration.set_version("1")
    end

    Database.User.create!

    migration("1")
  end

  def migration(nil) do
    Amnesia.stop()
    Amnesia.Schema.destroy
    Amnesia.Schema.create
    Amnesia.start()
    Database.create!([disk: [node()]])
    :ok = Database.wait(15000)

    Amnesia.transaction do
      Migration.set_version(@most_recent_version)
    end
  end

  def migration(_), do: nil

  defp db_exists? do
    case Database.wait(1000) do
      :ok -> true
      _ -> false
    end
  end
end
