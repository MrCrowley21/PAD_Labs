defmodule GatewayServer do
  use Plug.Router


  plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  plug :match
  plug :dispatch

  get "/home" do
    send_resp(conn, 200, Poison.encode!(%{session_id: "AGAYGUJNKDML3JPJKKGUFJC"}))
  end

  get "/report_retrieving" do
    reports = HTTPoison.get!("http://127.0.0.1:8001/reports/report_retrieving")
    status_code = Map.get(reports, :status_code)
    body = Map.get(reports, :body)
    send_resp(conn, status_code, body)
  end

end
