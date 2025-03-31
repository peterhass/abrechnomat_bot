defmodule AbrechnomatBot.Application do
  use Application

  def start(_type, _args) do
    case db_migrate() do
      :ok ->
        Supervisor.start_link(
          enabled_children([
            AbrechnomatBot.CommandReceiver,
            AbrechnomatBot.Commands.MessageContextStore,
            AbrechnomatBot.TaskPool.Supervisor,
            :systemd.ready()
          ]),
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

  defp enabled_children(list) do
    list
    |> Enum.map(&enabled_child/1)
    |> Enum.reject(&is_nil/1)
  end

  defp enabled_child(child) when is_atom(child) do
    case Application.get_env(:abrechnomat_bot, child)[:enable] do
      nil -> child
      true -> child
      _ -> nil
    end
  end

  defp enabled_child(child), do: child
end
