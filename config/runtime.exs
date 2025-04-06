import Config

telegram_token =
  case config_env() do
    :test -> nil
    _ -> System.fetch_env!("TELEGRAM_TOKEN")
  end

config :telegex,
  token: telegram_token,
  caller_adapter: {Finch, [receive_timeout: 5 * 1000]},
  hook_adapter: Bandit

case System.fetch_env("WEBHOOK_URL") do
  :error ->
    config :abrechnomat_bot, AbrechnomatBot.WebhookHandler, enable: false

  {:ok, webhook_url} ->
    config :abrechnomat_bot, AbrechnomatBot.PollingHandler, enable: false

    config :abrechnomat_bot, AbrechnomatBot.WebhookHandler,
      webhook_url: webhook_url,
      server_port:
        System.get_env("WEBHOOK_PORT", "8840")
        |> String.to_integer()
end
