defmodule SignalNetwork.MixProject do
  use Mix.Project

  def project do
    [
      app: :signal_network,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_envs: [precommit: :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SignalNetwork.Application, []}
    ]
  end

  defp deps do
    []
  end

  defp aliases do
    [
      precommit: ["format", "test"]
    ]
  end

  def cli do
    [preferred_envs: [precommit: :test]]
  end
end
