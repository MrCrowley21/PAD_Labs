defmodule Router do

  use Plug.Router

  plug Plug.Parsers, parsers: [:json], pass: ["text/*"], json_decoder: Poison
  plug :match
  plug :dispatch

  get "/health" do
    send_resp(conn, 200, Poison.encode!(%{session_id: "AGAYGUJNKDML3JPJKKGUFJC"}))
  end

  # get "/report_retrieving" do
  #   reports = HTTPoison.get!("http://127.0.0.1:8001/reports/report_retrieving")
  #   status_code = Map.get(reports, :status_code)
  #   body = Map.get(reports, :body)
  #   send_resp(conn, status_code, body)
  # end

  # post "/report_generation" do
  #   redirect_body =  conn.body_params
  #   headers = [{"Content-type", "application/json"}]
  #   report_response = HTTPoison.post!("http://127.0.0.1:8001/reports/report_generation", Poison.encode!(redirect_body), headers, [])
  #   status_code = Map.get(report_response, :status_code)
  #   body = Map.get(report_response, :body)
  #   send_resp(conn, status_code, Poison.encode!(body))
  # end

  # get "/data_visualization" do
  #   reports = HTTPoison.get!("http://127.0.0.1:8002/data_visualization")
  #   status_code = Map.get(reports, :status_code)
  #   body = Map.get(reports, :body)
  #   send_resp(conn, status_code, Poison.encode!(body))
  # end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

end
