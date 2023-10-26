defmodule ServiceDiscovery.MixProject do
  use Mix.Project

  def project do
    [
      app: :service_discovery,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ServiceDiscoverySupervisor, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:poison, "~> 5.0"},
      {:plug_cowboy, "~> 2.0"},
      {:ecto_sql, "~> 3.2"},
      {:grpc, "~> 0.7"},
      {:protobuf, "~> 0.11"},
      {:google_protos, "~> 0.1"},
      {:jason, "~> 1.2"},
    ]
  end
end
