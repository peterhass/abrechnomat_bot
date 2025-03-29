defmodule AbrechnomatBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :abrechnomat_bot,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AbrechnomatBot.Application, []},
      application: [],
      included_applications: [:ex_syslogger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:systemd, "~> 0.6"},
      {:ex_syslogger, "~> 1.5"},
      {:csv, "~> 2.3"},
      {:amnesia, "~> 0.2.7"},
      {:money, "~> 1.7.0"},
      {:phoenix_html, "~> 2.14.2"},

      # Telegex + optional deps
      {:telegex, "~> 1.9.0-rc.0"},
      {:finch, "~> 0.19.0"},
      {:multipart, "~> 0.4.0"}
    ]
  end

  defp aliases do
    [
      "db.create": ["amnesia.create -d AbrechnomatBot.Database --disk"]
    ]
  end
end
