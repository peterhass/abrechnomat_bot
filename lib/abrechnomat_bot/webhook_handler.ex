defmodule AbrechnomatBot.WebhookHandler do
  use Telegex.Hook.GenHandler
  alias AbrechnomatBot.UpdateQueue

  @impl true
  def on_boot do
    env_config = Application.get_env(:abrechnomat_bot, __MODULE__)
    {:ok, true} = Telegex.delete_webhook()
    {:ok, true} = Telegex.set_webhook(env_config[:webhook_url])

    %Telegex.Hook.Config{
      server_port: env_config[:server_port],
      secret_token: Telegex.Tools.gen_secret_token()
    }
  end

  @impl true
  def on_update(update) do
    # TODO: check for {:ok} ?
    UpdateQueue.queue(update)
    :ok
  end
end
