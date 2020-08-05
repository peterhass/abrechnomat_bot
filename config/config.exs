use Mix.Config

config :logger, level: :debug

token = case System.fetch_env("TELEGRAM_TOKEN") do
  {:ok, token} -> token
  _ -> nil
end

config :nadia, token: System.fetch_env("TELEGRAM_TOKEN")

