defmodule AbrechnomatBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :abrechnomat_bot,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:nadia, "~> 0.7.0"},
      {:amnesia, "~> 0.2.7"}
    ]
  end
end
