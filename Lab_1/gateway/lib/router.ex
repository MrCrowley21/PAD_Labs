defmodule Router do

  use Plug.Router

  plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  plug :match
  plug :dispatch

  require Logger

  @timeout 5000

  get "/status" do
    send_resp(conn, 200, Poison.encode!(%{status: "ok"}))
  end

  get "/health" do
    send_resp(conn, 200, Poison.encode!(%{status: "ok"}))
  end

  get "/report_retrieving" do
    service_address = GatewayService.find_service("report_service")
    if service_address.ready do
      try do
        reports = HTTPoison.get!("http://" <> service_address.address <> ":" <> service_address.inner_port <> "/reports/report_retrieving", [recv_timeout: @timeout])
        status_code = Map.get(reports, :status_code)
        body = Map.get(reports, :body)
        send_resp(conn, status_code, body)
      rescue
        HTTPoison.Error ->
          Logger.info("Timeout exceeded")
          send_resp(conn, 200, "Failed to perform the last updates. :(")
      end
    else
      send_resp(conn, 503, "Sorry! We are encountering overload on our services. :( Come back later!")
    end
  end

  post "/report_generation" do
    redirect_body =  conn.body_params
    headers = [{"Content-type", "application/json"}]
    service_address = GatewayService.find_service("report_service")
    if service_address.ready do
      try do
        report_response = HTTPoison.post!("http://" <> service_address.address <> ":" <> service_address.inner_port <>  "/reports/report_generation",
        Poison.encode!(redirect_body), headers, [recv_timeout: @timeout])
        status_code = Map.get(report_response, :status_code)
        body = Map.get(report_response, :body)
        send_resp(conn, status_code, Poison.encode!(body))
      rescue
        HTTPoison.Error ->
          Logger.info("Timeout exceeded")
          send_resp(conn, 200, "Failed to perform the last updates. :(")
      end
    else
      send_resp(conn, 503, "Sorry! We are encountering overload on our services. :( Come back later!")
    end
  end

  get "/data_visualization" do
    service_address = GatewayService.find_service("report_service")
    if service_address.ready do
      try do
        reports = HTTPoison.get!("http://" <> service_address.address <> ":" <> service_address.inner_port <>  "/data_visualization", [recv_timeout: @timeout])
        status_code = Map.get(reports, :status_code)
        body = Map.get(reports, :body)
        send_resp(conn, status_code, Poison.encode!(body))
      rescue
        HTTPoison.Error ->
          Logger.info("Timeout exceeded")
          send_resp(conn, 200, "Failed to perform the last updates. :(")
      end
    else
      send_resp(conn, 503, "Sorry! We are encountering overload on our services. :( Come back later!")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

end
