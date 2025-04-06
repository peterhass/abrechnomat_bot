defmodule AbrechnomatBot.WebhookHandler do
  use Telegex.Hook.GenHandler
  alias AbrechnomatBot.UpdateQueue

  @impl true
  def on_boot do
    {:ok, true} = Telegex.delete_webhook()

    Logger.info("Registering webhook: #{webhook_url()}")
    secret_token = Telegex.Tools.gen_secret_token()
    {:ok, true} = Telegex.set_webhook(webhook_url(), secret_token: secret_token)

    %Telegex.Hook.Config{
      server_port: config()[:server_port],
      secret_token: secret_token
    }
  end

  @impl true
  def on_update(update) do
    Logger.info("Received update: #{inspect(update)}")
    UpdateQueue.queue(update)
  end

  @hook_path "/updates_hook"
  defp webhook_url do
    URI.parse(config()[:webhook_url])
    # hard-coded in Telegex
    |> URI.merge(@hook_path)
    |> URI.to_string()
  end

  defp config do
    Application.get_env(:abrechnomat_bot, __MODULE__)
  end
end
