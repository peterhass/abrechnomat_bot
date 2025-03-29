defmodule AbrechnomatBot.Application do
  use Application

  def start(_type, _args) do
    case db_migrate() do
      :ok ->
        children = [
          AbrechnomatBot.CommandReceiver,
          AbrechnomatBot.Commands.MessageContextStore,
          # systemd healthcheck 
          :systemd.ready()
        ]

        Supervisor.start_link(
          children,
          strategy: :one_for_one,
          name: AbrechnomatBot.Supervisor
        )

      {:error, reason} ->
        {:error, :migration_error, reason}
    end
  end

  defp db_migrate do
    case System.get_env("DB_CREATE") do
      "true" -> AbrechnomatBot.Database.Migrations.create()
      _ -> AbrechnomatBot.Database.Migrations.run()
    end
  end
end
