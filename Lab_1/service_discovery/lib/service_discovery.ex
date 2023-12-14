defmodule ServiceDiscovery.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Server.Interceptors.Logger
  run ServiceDiscovery.Server
end

defmodule ServiceDiscovery.Server do
  use GRPC.Server, service: ServiceDiscoveryRegister.Service
  require Logger

  @max_load_per_service 20
  @max_service_call 2
  @timeout 5000

  @spec register_service(Register.t(), GRPC.Server.Stream.t()) :: RegistrationResult.t()
  def register_service(request, _stream) do
    :ets.insert(:gateway, {request.inner_port, request.address, request.extern_port, request.service_type})
    Logger.info("New registered service of type #{request.service_type}, on address: #{request.address}")
    extracted_data = :ets.tab2list(:gateway)
    IO.inspect(extracted_data)
    %RegistrationResult{success: 1}
  end

  @spec find_service(atom() | %{:service_type => binary(), optional(any()) => any()}, any()) ::
          ReturnService.t()
  def find_service(request, _stream) do
    extracted_data = :ets.tab2list(String.to_atom(request.service_type))
    Logger.info("List of available services:")
    IO.inspect(extracted_data)
    evaluated_services = choose_less_loaded_service(extracted_data)
    chosen_replica = find_available_replica(evaluated_services, @max_service_call)
    if chosen_replica != "unavailable" do
      Logger.info("The chosen service...")
      IO.inspect(chosen_replica)
      %ReturnService{address: chosen_replica|> elem(1), inner_port: to_string(chosen_replica|> elem(2)), ready: (chosen_replica|> elem(0) < @max_load_per_service)}
    else
      %ReturnService{address: chosen_replica, inner_port: "0", ready: False}
    end
  end

  defp choose_less_loaded_service(service_list) do
    load_per_server =
      for service <- service_list do
        address = service|> elem(0)
        port = service|> elem(1)
        state = HTTPoison.get!("http://#{address}:#{port}/health", timeout: @timeout)
        json_data = Jason.decode!(state.body)
        load = Map.get(json_data, "load")
        if load > @max_load_per_service do
          Logger.alert("Critical load on server #{address}:#{port}")
        end
        {load, address, port}
      end
    load_per_server
  end

  defp find_available_replica([evaluated_address | address_list], tries) when tries > 0 do
    try do
      address = evaluated_address|> elem(1)
      port = evaluated_address|> elem(2)
      IO.inspect(evaluated_address)
      IO.inspect(address)
      IO.inspect(port)
      # _ = HTTPoison.get!("http://#{address}:#{port}/status", timeout: @timeout * 3.5)
      Logger.info("Suitable replica found: #{address}.")
      evaluated_address
    rescue
      HTTPoison.Error ->
        find_available_replica(address_list, tries - 1)
    end
  end

  defp find_available_replica([_evaluated_address | _address_list], tries) when tries == 0 do
    "unavailable"
  end

end
