defmodule CircuitBreaker do
  use GenServer
  require Logger

  @timeout 500

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    GenServer.cast(__MODULE__, {:check_servicies})
    {:ok, []}
  end

  def handle_cast({:check_servicies}, state) do
    service_list = :ets.tab2list(:gateway) ++ :ets.tab2list(:report_service) ++ :ets.tab2list(:graphic_service)
    for service <- service_list do
      address = service|> elem(1)
      port = service|> elem(0)
      try do
        IO.inspect(address)
        IO.inspect(port)
        _response = HTTPoison.get!("http://localhost:#{port}/health", timeout: @timeout)
        Logger.info("Circuit Breaker: #{address} status: ok.")
      rescue
        HTTPoison.Error ->
          Logger.info("Circuit Breaker: Timeout exceeded. Testing server for availability.")
          status = test_server_availability("http://locallhost:#{port}/health", 3)
          if status == "fail" do
            Logger.info("Circuit Breaker: #{address} failed.")
            service_type = service|> elem(3)
            IO.inspect(service_type)
            #extern_port = service|> elem(2)
            :ets.delete(String.to_atom(service_type), port)
            IO.inspect(:ets.tab2list(String.to_atom(service_type)))
            Logger.info("Service #{service_type} at address #{address} has failed. Hence, deleted!")
          end
        :success
      end
    end
    :timer.sleep(5000)
    GenServer.cast(__MODULE__, {:check_servicies})
    {:noreply, state}
  end

  def test_server_availability(address, tries) when (tries <= 3) and (tries > 0) do
    try do
      HTTPoison.get!(address, timeout: @timeout * 3.5)
      Logger.info("Circuit Breaker: #{address} status: ok.")
      "success"
    rescue
      HTTPoison.Error ->
        test_server_availability(address, tries - 1)
    end
  end

  def test_server_availability(_address, 0) do
    "fail"
  end

end
