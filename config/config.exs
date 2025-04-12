import Config

config :logger, :ex_syslogger_error,
  level: :error,
  format: "$node $metadata $message",
  metadata: [:module, :line, :function],
  ident: "abrechnomat_bot",
  facility: :local0,
  option: [:pid, :cons]

config :logger, :ex_syslogger_debug,
  level: :debug,
  format: "$message",
  ident: "abrechnomat_bot",
  facility: :local1,
  option: [:pid, :perror]

config :ex_cldr,
  default_locale: "en",
  default_backend: AbrechnomatBot.Cldr

import_config "#{Mix.env()}.exs"
