defmodule AbrechnomatBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :abrechnomat_bot,
      version: "0.1.0",
      elixir: "~> 1.10",
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
      application: [:nadia, :amnesia]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nadia, "~> 0.7.0"},
      {:jason, "~> 1.1"}, # needed for nadia??
      {:amnesia, "~> 0.2.7"},
      {:money, "~> 1.7.0"},
      {:phoenix_html, "~> 2.14.2"}
    ]
  end

  defp aliases do
    [
      "db.create": ["amnesia.create -d AbrechnomatBot.Database --disk"]
    ]
  end

end
