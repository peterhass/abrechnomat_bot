import Config

telegram_token =
  case config_env() do
    :test -> nil
    _ -> System.fetch_env!("TELEGRAM_TOKEN")
  end

config :telegex,
  token: telegram_token,
  caller_adapter: {Finch, [receive_timeout: 5 * 1000]}
