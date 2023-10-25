defmodule GatewayService do
  use GenServer
  require Logger

  def start_link(channel) do
    GenServer.start_link(__MODULE__, channel, name: __MODULE__)
  end


  # Logical Functions
  def init(channel) do
    host_name = find_registration_data()
    register_gateway("gateway", host_name, 12, 12, channel)
    Logger.info("Gateway got regisered into Service Discovery!")
    {:ok, nil}
  end

  defp find_registration_data() do
    {host_name, _} = System.cmd("sh", ["-c", "echo $HOSTNAME"])
    host_name = String.replace(host_name, "\n", "")
    Logger.info(host_name)
    host_name
  end

  defp register_gateway(service_type, address, inner_port, extern_port, channel) do
    request = %Register{service_type: service_type, address: address, inner_port: inner_port, extern_port: extern_port}
    Logger.info(request)
    response = channel|> ServiceDiscoveryRegister.Stub.register_service(request)
    IO.inspect(response)
    {:ok, response}
  end

  # # Functions to make a gRPC request
  # def register_service(service_type, address, inner_port, extern_port) do
  #   GenServer.call(__MODULE__, {:register, service_type, address, inner_port, extern_port})
  # end

  # # Functions to handle GenServer handle_info callback to send gRPC request
  # def handle_call(service_type, address, inner_port, extern_port, _from, channel) do
  #   request = %Register{service_type: service_type, address: address, inner_port: inner_port, extern_port: extern_port}
  #   response = channel|> ServiceDiscovery.Stub.register(request, timeout: 2000)
  #   {:response, channel, response}
  # end

end
