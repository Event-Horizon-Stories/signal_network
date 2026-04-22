import Config

config :signal_network, SignalNetwork.Endpoint,
  secret_key_base: String.duplicate("signal-network", 5),
  server: false
