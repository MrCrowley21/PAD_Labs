defmodule ServiceDiscovery.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Server.Interceptors.Logger
  run ServiceDiscovery.Server
end

defmodule ServiceDiscovery.Server do
  use GRPC.Server, service: ServiceDiscoveryRegister.Service
  require Logger

  @spec register_service(Register.t(), GRPC.Server.Stream.t()) :: RegistrationResult.t()
  def register_service(request, _stream) do
    :ets.insert(:gateway, {request.service_type, request.address, request.inner_port, request.extern_port})
    Logger.info("New registered service of type #{request.service_type}, on address: #{request.address}")
    extracted_data = :ets.tab2list(:gateway)
    IO.inspect(extracted_data)
    %RegistrationResult{success: 1}
  end

end
