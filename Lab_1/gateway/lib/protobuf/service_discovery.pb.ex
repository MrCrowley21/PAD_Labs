defmodule Register do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :service_type, 1, type: :string, json_name: "serviceType"
  field :address, 2, type: :string
  field :inner_port, 3, type: :int32, json_name: "innerPort"
  field :extern_port, 4, type: :int32, json_name: "externPort"
end

defmodule RegistrationResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :success, 1, type: :int32
end

defmodule ServiceDiscoveryRegister.Service do
  @moduledoc false

  use GRPC.Service, name: "service_discovey_register", protoc_gen_elixir_version: "0.12.0"

  rpc :registerService, Register, RegistrationResult

end

defmodule ServiceDiscoveryRegister.Stub do
  @moduledoc false

  use GRPC.Stub, service: ServiceDiscoveryRegister.Service
end
