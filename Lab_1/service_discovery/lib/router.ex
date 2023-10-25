defmodule Router do
  use Plug.Router

  plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  plug :match
  plug :dispatch

  post "/register" do
    body = conn.body_params
    ServiceDiscovery.register(Map.get(body, "service_type"), Map.get(body, "address"), Map.get(body, "inner_port"), Map.get(body, "extern_port"))
    send_resp(conn, 200, "Success")
  end

end
