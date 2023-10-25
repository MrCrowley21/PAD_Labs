defmodule Gateway do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Gateway started its activity...")

    Logger.info("Connectting to the Service Discovery...")
    {:ok, service_discovery} = GRPC.Stub.connect("localhost:4001", timeout: 5000)
    # Logger.info("Connection... succes!")

    # Logger.info("Connectting to the Graphics Manager service...")
    # {:ok, report_manager} = GRPC.Stub.connect("localhost:8002")

    children = [
      {Plug.Cowboy,
      scheme: :http,
      plug: Router,
      options: [port: 8000]},
      %{
        id: GatewayService,
        start: {GatewayService, :start_link, [service_discovery]},
        restart: :permanent,
      }
     ]

     Supervisor.start_link(children, strategy: :one_for_one)
  end

end
