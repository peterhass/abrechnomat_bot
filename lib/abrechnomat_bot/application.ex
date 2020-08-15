defmodule AbrechnomatBot.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    case db_migrate() do
      :ok ->
        children = [
          worker(AbrechnomatBot.CommandReceiver, [])
        ]

        opts = [strategy: :one_for_one, name: AbrechnomatBot.Supervisor]
        Supervisor.start_link(children, opts)
      {:error, reason} ->
        {:error, :migration_error, reason}
    end
  end

  defp db_migrate do
    AbrechnomatBot.Database.Migrations.run()
  end
end
