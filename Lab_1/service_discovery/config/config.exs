import Config

config :service_discovery, ServiceDiscoverySupervisor,
  http: [ip: {0,0,0,0}, port: 4000]
