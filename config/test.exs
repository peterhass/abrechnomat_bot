import Config

config :logger, level: :debug
config :abrechnomat_bot, AbrechnomatBot.PollingHandler, enable: false
config :abrechnomat_bot, AbrechnomatBot.WebhookHandler, enable: false
config :abrechnomat_bot, AbrechnomatBot.UpdateQueue, enable: false
