defmodule Router do
  use Plug.Router
  require Logger

  plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  plug :match
  plug :dispatch

  get "/status" do
    send_resp(conn, 200, Poison.encode!(%{status: "ok"}))
  end

  post "/register" do
    Logger.info("Processing new register request...")
    body = conn.body_params
    service_type = Map.get(body, "service_type")
    address = Map.get(body, "address")
    :ets.insert_new(String.to_atom(service_type), {address, Map.get(body, "inner_port"), Map.get(body, "extern_port"), service_type})
    IO.inspect(:ets.tab2list(String.to_atom(service_type)))
    Logger.info("Successfully connected to #{service_type}, at address: #{address}")
    send_resp(conn, 200, Poison.encode!(%{success: 1}))
  end

  match _ do
    send_resp(conn, 404, "Oopsi! Not such an address")
  end

end
