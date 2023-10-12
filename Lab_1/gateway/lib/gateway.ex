defmodule Gateway do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Gateway started its activity...")

    children = [
      {Plug.Cowboy,
      scheme: :http,
      plug: GatewayServer,
      options: [port: 8000]},
     ]

     Supervisor.start_link(children, strategy: :one_for_all)
  end

end
