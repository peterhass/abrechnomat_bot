import Config

config :nadia, token: {:system, "TELEGRAM_TOKEN", nil}

import_config "#{Mix.env()}.exs"
