defmodule AbrechnomatBot.Database.Migrations do
  alias AbrechnomatBot.Database
  alias AbrechnomatBot.Database.Migration
  require Amnesia
  require Amnesia.Helper

  @most_recent_version "2"

  def run do
    get_version()
    |> migration
  end

  def create do
    Amnesia.stop()
    Amnesia.Schema.destroy()
    Amnesia.Schema.create()
    Amnesia.start()
    Database.create!(disk: [node()])
    :ok = Database.wait(15000)

    Amnesia.transaction do
      Migration.set_version(@most_recent_version)
    end

    :ok
  end

  def migration("1") do
    IO.puts("Migrating to version 2 ...")
    Database.Chat.create!()

    Amnesia.transaction do
      Migration.set_version("2")
    end

    migration("2")
  end

  def migration("initialized") do
    IO.puts("Migrating to version 1 ...")

    Amnesia.transaction do
      Migration.set_version("1")
    end

    Database.User.create!()

    migration("1")
  end

  def migration(_), do: :ok

  defp get_version do
    case Database.wait(1000) do
      :ok ->
        Amnesia.transaction(&Migration.get_current_version/0)

      _ ->
        IO.puts(
          :stderr,
          "Cannot access database, it's either faulty or doesn't exist. Set env variable DB_CREATE to true to setup database on first run."
        )

        nil
    end
  end
end
