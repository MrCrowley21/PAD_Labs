defmodule Gateway do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Gateway started its activity...")

    Logger.info("Connectting to the Service Discovery...")

    children = [
      {Plug.Cowboy,
      scheme: :http,
      plug: Router,
      options: [port: 8000]},
      %{
        id: GatewayService,
        start: {GatewayService, :start_link, []},
        restart: :permanent,
      }
     ]

     Supervisor.start_link(children, strategy: :one_for_one)
  end

end
