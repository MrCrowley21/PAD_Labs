defmodule GatewayServiceWeb.HealthController do
  use GatewayWeb, :controller

  def get_health(conn, _params) do
    %{"data_base": "none", "load": "ok"}
  end

end
