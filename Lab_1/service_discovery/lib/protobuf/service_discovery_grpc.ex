defmodule ServiceDiscoveryGRPC do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Logger.info("Starting Service Discovery gRPC activity...")
    Logger.info(GRPC.Server.start(ProtoServiceDiscovery, 4000))
    {:ok, nil}
  end

  # Define calls

  def register_service(service_type, address, inner_port, extern_port) do
    GenServer.call(__MODULE__, {:register_service, service_type, address, inner_port, extern_port})
  end

  # Define calls handling

  def handle_call(service_type, address, inner_port, extern_port, _from, channel) do
    request = %Register{service_type: service_type, address: address, inner_port: inner_port, extern_port: extern_port}
    response = channel|> Proto.Stub.register_service(request, timeout: 2000)
    Logger.info("New service registered...")
    {:response, channel, response}
  end

end
