defmodule ServiceDiscoverySupervisor do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Service Discovery started its activity...")

    :ets.new(:gateway, [:bag, :public, :named_table])
    :ets.new(:report_service, [:bag, :public, :named_table])
    :ets.new(:graphic_service, [:bag, :public, :named_table])

    children = [
      {Plug.Cowboy,
      scheme: :http,
      plug: Router,
      options: [port: 4000]},
      {GRPC.Server.Supervisor, endpoint: ServiceDiscovery.Endpoint, port: 4001, start_server: true},
      %{
        id: CircuitBreaker,
        start: {CircuitBreaker, :start_link, []},
        restart: :permanent,
      }
    ]
     Supervisor.start_link(children, strategy: :one_for_one)
  end

end
