defmodule Bridge.MixProject do
  use Mix.Project

  def project do
    [
      app: :bridge,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Bridge.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:radar, github: "ironbay/radar"},
      {:fig, github: "ironbay/fig"},
      {:slack, "~> 0.12.0"},
      {:distillery, "~> 1.4", runtime: false},
    ]
  end
end
