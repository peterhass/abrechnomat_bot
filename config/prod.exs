import Config

config :logger,
  backends: [
    {ExSyslogger, :ex_syslogger_error},
    {ExSyslogger, :ex_syslogger_debug}
  ]
