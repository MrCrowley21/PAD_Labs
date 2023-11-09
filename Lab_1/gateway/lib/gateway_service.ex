defmodule GatewayService do
  use GenServer
  require Logger

  @timeout 5000

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: :gateway_service)
  end


  # Logical Functions
  def init(_args) do
    host_name = find_registration_data()
    register_gateway("gateway", host_name, 8000, 8000)
    Logger.info("Gateway got regisered into Service Discovery!")
    {:ok, nil}
  end

  defp find_registration_data() do
    {host_name, _} = System.cmd("sh", ["-c", "echo $HOSTNAME"])
    host_name = String.replace(host_name, "\n", "")
    Logger.info(host_name)
    host_name
  end

  defp register_gateway(service_type, address, inner_port, extern_port) do
    # localhost
    {:ok, channel} = GRPC.Stub.connect("localhost:4001", timeout: @timeout)
    request = %Register{service_type: service_type, address: address, inner_port: inner_port, extern_port: extern_port}
    response = channel|> ServiceDiscoveryRegister.Stub.register_service(request)
    IO.inspect(response)
    {:ok, response}
  end

  def find_service(service_type) do
    # localhost
    {:ok, channel} = GRPC.Stub.connect("localhost:4001", timeout: @timeout)
    request = %RequestService{service_type: service_type}
    {_, response} = channel|> ServiceDiscoveryRegister.Stub.find_service(request)
    Logger.info("Service found...")
    response
  end

end
