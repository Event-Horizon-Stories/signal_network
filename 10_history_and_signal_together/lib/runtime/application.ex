defmodule SignalNetwork.Application do
  @moduledoc """
  Starts the lesson application.

  Lesson 1 does not need runtime processes yet, but keeping the supervision tree
  in place makes later chapters cumulative instead of structural rewrites.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Phoenix.PubSub, name: SignalNetwork.pubsub_name()},
        id: SignalNetwork.PubSub
      ),
      Supervisor.child_spec({Phoenix.PubSub, name: SignalNetwork.planet_bus_name(:mars)},
        id: SignalNetwork.MarsBus
      ),
      Supervisor.child_spec({Phoenix.PubSub, name: SignalNetwork.planet_bus_name(:deimos)},
        id: SignalNetwork.DeimosBus
      ),
      SignalNetwork.Web.Presence,
      SignalNetwork.Consumers.ControlRoom,
      SignalNetwork.Consumers.AlertSink,
      SignalNetwork.Consumers.AnalyticsSink,
      SignalNetwork.Network.StormGate,
      SignalNetwork.Network.PartitionTracker,
      SignalNetwork.History.EventJournal,
      SignalNetwork.Web.Endpoint,
      SignalNetwork.Web.ChannelBridge,
      Supervisor.child_spec(
        {SignalNetwork.Network.PlanetRelay,
         planet: :mars, name: SignalNetwork.planet_relay_name(:mars)},
        id: SignalNetwork.MarsRelay
      ),
      Supervisor.child_spec(
        {SignalNetwork.Network.PlanetRelay,
         planet: :deimos, name: SignalNetwork.planet_relay_name(:deimos)},
        id: SignalNetwork.DeimosRelay
      )
    ]

    opts = [strategy: :one_for_one, name: SignalNetwork.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
