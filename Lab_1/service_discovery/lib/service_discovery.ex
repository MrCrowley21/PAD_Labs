defmodule ServiceDiscovery.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Server.Interceptors.Logger
  run ServiceDiscovery.Server
end

defmodule ServiceDiscovery.Server do
  use GRPC.Server, service: ServiceDiscoveryRegister.Service
  require Logger

  @max_load_per_service 15
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
    evaluated_service = choose_less_loaded_service(extracted_data)
    Logger.info("The chosen service...")
    IO.inspect(evaluated_service)
    %ReturnService{address: evaluated_service|> elem(1), inner_port: evaluated_service|> elem(2), ready: (evaluated_service|> elem(0) < @max_load_per_service)}
  end

  defp choose_less_loaded_service(service_list) do
    load_per_server =
      for service <- service_list do
        address = service|> elem(1)
        port = service|> elem(0)
        state = HTTPoison.get!("http://#{address}:#{port}/health", timeout: @timeout)
        json_data = Jason.decode!(state.body)
        load = Map.get(json_data, "load")
        if load > @max_load_per_service do
          Logger.alert("Critical load on server #{address}:#{port}")
        end
        {load, address, port}
      end
    load_per_server = load_per_server|> List.keysort(0)
    List.first(load_per_server)
  end

end
