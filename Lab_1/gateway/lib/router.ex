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

  get "/download_latest" do
    redirect_body =  conn.params
    IO.inspect(conn)
    headers = [{"Content-type", "application/json"}]
    service_address = GatewayService.find_service("report_service")
    if service_address.ready do
      try do
        report_response = HTTPoison.get!("http://" <> service_address.address <> ":" <> service_address.inner_port <>  "/reports/download_latest",
        headers, [params: %{"connectionId": redirect_body["connectionId"]}])
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
    service_address = GatewayService.find_service("graphic_service")
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

  post "/new_stats" do
    body =  conn.body_params
    headers = [{"Content-type", "application/json"}]
    service_address_report = GatewayService.find_service("report_service")
    service_address_graphic = GatewayService.find_service("graphic_service")
    if service_address_report.ready and service_address_graphic.ready do
      report_body = nil
      diagram_body = nil
      try do
        report_response = HTTPoison.post!("http://" <> service_address_report.address <> ":" <> service_address_report.inner_port <>  "/reports/report_generation",
        Poison.encode!(body), headers, [recv_timeout: @timeout])
        status_code = Map.get(report_response, :status_code)
        report_body = Map.get(report_response, :body)
        graphic_response = HTTPoison.post!("http://" <> service_address_graphic.address <> ":" <> service_address_graphic.inner_port <>  "/diagram_generation",
        Poison.encode!(body), headers, [recv_timeout: @timeout])
        status_code = Map.get(graphic_response, :status_code)
        diagram_body = Map.get(graphic_response, :body)
        send_resp(conn, 200, "Successful updated")
      rescue
        HTTPoison.Error ->
          try do
            Logger.info("SAGA Compensation")
            case report_body do
              nil ->
                Logger.info("Problem is not here")
              _ ->
                HTTPoison.request!(:delete, "http://" <> service_address_report.address <> ":" <> service_address_report.inner_port <>  "/reports/report_generation",
                Poison.encode!(report_body), headers)
                send_resp(conn, 200, "Failed to perform the last updates. :(")
            end
            case diagram_body do
              nil ->
                send_resp(conn, 200, "Failed to perform the last updates. :(")
              _ ->
                HTTPoison.request!(:delete, "http://" <> service_address_report.address <> ":" <> service_address_report.inner_port <>  "/reports/report_generation",
                Poison.encode!(report_body), headers)
                send_resp(conn, 200, "Failed to perform the last updates. :(")
            end
          rescue
            HTTPoison.Error ->
              send_resp(conn, 200, "Compensation failed")
          end
      end
    else
      send_resp(conn, 503, "Sorry! We are encountering overload on our services. :( Come back later!")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

end
