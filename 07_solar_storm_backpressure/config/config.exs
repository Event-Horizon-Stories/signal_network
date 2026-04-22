import Config

config :signal_network, pubsub_server: SignalNetwork.PubSub

config :signal_network, SignalNetwork.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [formats: [json: SignalNetwork.Endpoint], layout: false],
  pubsub_server: SignalNetwork.PubSub,
  secret_key_base: String.duplicate("signal-network", 5),
  server: false

config :logger, level: :warning
