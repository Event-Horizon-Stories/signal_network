defmodule SignalNetwork do
  @moduledoc """
  The public entry point for the Interplanetary Signal Network lessons.

  Lesson 1 starts with the wrong shape on purpose: dashboards poll a
  distributed world for the latest state. The code is small, but the costs are
  already visible:

  - every poll rereads every source
  - snapshots go stale between requests
  - the dashboard pays the cost even when nothing changed
  """

  alias Phoenix.PubSub

  alias SignalNetwork.{
    Consumers.AlertSink,
    Consumers.AnalyticsSink,
    Consumers.ControlRoom,
    History.EventJournal,
    Network.PartitionTracker,
    Web.Presence,
    Signals.Signal,
    Network.StormGate,
    Signals.World
  }

  @doc """
  Builds a fresh world with a few known sources already transmitting.

  ## Examples

      iex> world = SignalNetwork.new_world()
      iex> is_list(world.signals)
      true
  """
  @spec new_world() :: World.t()
  def new_world do
    World.new(sample_signals())
  end

  @doc """
  Returns a dashboard snapshot by polling every known source.

  The snapshot is accurate for the instant it was taken, but it does not update
  itself after new signals arrive.

  ## Examples

      iex> world = SignalNetwork.new_world()
      iex> snapshot = SignalNetwork.poll_dashboard(world, dashboard_id: "ops")
      iex> snapshot.dashboard_id
      "ops"
  """
  @spec poll_dashboard(World.t(), keyword()) :: SignalNetwork.Signals.Snapshot.t()
  def poll_dashboard(world, opts \\ []) do
    dashboard_id = Keyword.get(opts, :dashboard_id, "mission-control")
    World.poll_dashboard(world, dashboard_id)
  end

  @doc """
  Appends a new signal to the world.

  ## Examples

      iex> world = SignalNetwork.new_world()
      iex> world = SignalNetwork.emit(world, %{source: :mars_colony, topic: "alerts:mars", event: :oxygen_low, payload: %{percent: 18}})
      iex> List.last(world.signals).event
      :oxygen_low
  """
  @spec emit(World.t(), map()) :: World.t()
  def emit(world, attrs) do
    World.emit(world, attrs)
  end

  @doc """
  Returns the world reduced into the latest known value for each topic.
  """
  @spec current_state(World.t()) :: map()
  def current_state(world) do
    World.current_state(world)
  end

  @doc """
  Subscribes the calling process to a topic on the shared PubSub bus.
  """
  @spec listen(String.t()) :: :ok | {:error, term()}
  def listen(topic) do
    PubSub.subscribe(pubsub_name(), topic)
  end

  @doc """
  Broadcasts a signal to its topic and to the shared control-room topic.
  """
  @spec announce(map()) :: Signal.t()
  def announce(attrs) do
    signal = runtime_signal(attrs)
    :ok = StormGate.dispatch(signal)

    signal
  end

  @doc """
  Appends a signal to the durable journal without broadcasting it.
  """
  @spec journal_signal(map()) :: Signal.t()
  def journal_signal(attrs) do
    signal = runtime_signal(attrs)
    :ok = EventJournal.append(signal)
    signal
  end

  @doc """
  Writes a signal to the journal and broadcasts it live.
  """
  @spec record_and_announce(map()) :: Signal.t()
  def record_and_announce(attrs) do
    signal = journal_signal(attrs)
    :ok = StormGate.dispatch(signal)
    signal
  end

  @doc """
  Returns the latest state maintained by the live control room.
  """
  @spec dashboard_snapshot() :: %{optional(String.t()) => Signal.t()}
  def dashboard_snapshot do
    ControlRoom.snapshot()
  end

  @doc """
  Clears the runtime projection between tests or demos.
  """
  @spec reset_runtime!() :: :ok
  def reset_runtime! do
    ControlRoom.reset()
    AlertSink.reset()
    AnalyticsSink.reset()
    StormGate.reset()
    PartitionTracker.reset()
    EventJournal.reset()
  end

  @doc """
  Returns the alerts raised by the alert sink.
  """
  @spec alerts() :: [Signal.t()]
  def alerts do
    AlertSink.notifications()
  end

  @doc """
  Returns the analytics counters keyed by event name.
  """
  @spec analytics() :: %{optional(atom()) => non_neg_integer()}
  def analytics do
    AnalyticsSink.counts()
  end

  @doc """
  Returns the channel topic used by operator dashboards.
  """
  @spec channel_topic() :: String.t()
  def channel_topic, do: "operations:mission-control"

  @doc """
  Tracks a connected system in the shared Presence topic.
  """
  @spec track_system(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def track_system(system_id, meta) do
    Presence.track(self(), systems_topic(), system_id, meta)
  end

  @doc """
  Lists the systems that are currently marked online.
  """
  @spec systems_online() :: map()
  def systems_online do
    Presence.list(systems_topic())
  end

  @doc """
  Lists the operators currently present in mission control.
  """
  @spec operators_online() :: map()
  def operators_online do
    Presence.list(channel_topic())
  end

  @doc """
  Returns the low-priority signals that were dropped during a storm.
  """
  @spec dropped_signals() :: [Signal.t()]
  def dropped_signals do
    StormGate.dropped_signals()
  end

  @doc """
  Returns the sequence gaps detected after a source reconnects.
  """
  @spec gaps() :: [map()]
  def gaps do
    PartitionTracker.gaps()
  end

  @doc """
  Recovers the most recent missing sequence range for one source from the journal.
  """
  @spec recover_gap(atom()) :: [Signal.t()]
  def recover_gap(source) do
    source
    |> PartitionTracker.gaps()
    |> Enum.find(fn gap -> gap.source == source end)
    |> case do
      nil -> []
      %{missed_sequences: sequences} -> EventJournal.lookup(source, sequences)
    end
  end

  @doc """
  Subscribes the caller to one of the priority feeds.
  """
  @spec listen_priority(Signal.priority()) :: :ok | {:error, term()}
  def listen_priority(priority) do
    listen(priority_topic(priority))
  end

  @doc """
  Builds the full lesson narrative in one inspectable map.

  The returned structure is used by the README examples, the test suite, and
  the Livebook companion.
  """
  @spec bootstrap_story!() :: map()
  def bootstrap_story! do
    reset_runtime!()

    world = new_world()
    first_snapshot = poll_dashboard(world, dashboard_id: "mission-control")

    world_after_alert =
      emit(world, %{
        source: :mars_colony,
        topic: "alerts:mars",
        event: :oxygen_low,
        payload: %{zone: "hab-3", percent: 18},
        priority: :high
      })

    refreshed_snapshot = poll_dashboard(world_after_alert, dashboard_id: "mission-control")

    :ok = listen("trade:shipment-17")

    broadcast_signal =
      announce(%{
        source: :trade_authority,
        topic: "trade:shipment-17",
        event: :shipment_delayed,
        payload: %{status: "delayed", reason: "solar winds", minutes: 42},
        priority: :normal
      })

    inbox_signal =
      receive do
        %Signal{} = signal -> signal
      after
        200 -> raise "expected a PubSub broadcast to arrive"
      end

    %{
      world: world_after_alert,
      first_snapshot: first_snapshot,
      stale_snapshot: first_snapshot,
      refreshed_snapshot: refreshed_snapshot,
      first_state: first_snapshot.latest_by_topic,
      refreshed_state: refreshed_snapshot.latest_by_topic,
      broadcast_signal: broadcast_signal,
      inbox_signal: inbox_signal,
      live_state: dashboard_snapshot(),
      alerts: alerts(),
      analytics: analytics()
    }
  end

  @doc """
  Creates the starter signals for the lesson.
  """
  @spec sample_signals() :: [Signal.t()]
  def sample_signals do
    [
      Signal.new!(%{
        tick: 1,
        source: :mars_colony,
        topic: "telemetry:mars",
        event: :oxygen_level,
        payload: %{zone: "hab-3", percent: 97}
      }),
      Signal.new!(%{
        tick: 2,
        source: :trade_authority,
        topic: "trade:shipment-17",
        event: :shipment_departed,
        payload: %{status: "departed", destination: "deimos"}
      }),
      Signal.new!(%{
        tick: 3,
        source: :orbital_ship_7,
        topic: "presence:orbital_ship_7",
        event: :ship_online,
        payload: %{callsign: "Kestrel-7", online: true}
      })
    ]
  end

  @doc """
  Returns the registered name of the lesson PubSub server.
  """
  @spec pubsub_name() :: atom()
  def pubsub_name, do: SignalNetwork.PubSub

  @doc """
  Returns the topic used by the control room to observe every signal.
  """
  @spec control_room_topic() :: String.t()
  def control_room_topic, do: "signals:all"

  @doc """
  Returns the presence topic for connected systems.
  """
  @spec systems_topic() :: String.t()
  def systems_topic, do: "systems:mission-control"

  @doc """
  Returns the topic used for a given priority feed.
  """
  @spec priority_topic(Signal.priority()) :: String.t()
  def priority_topic(:high), do: "priority:high"
  def priority_topic(:normal), do: "priority:normal"
  def priority_topic(:low), do: "priority:low"

  @doc """
  Broadcasts a signal from a planet-local bus into the wider network.
  """
  @spec announce_from_planet(atom(), map()) :: Signal.t()
  def announce_from_planet(planet, attrs) do
    signal = runtime_signal(attrs)

    :ok =
      PubSub.broadcast(planet_bus_name(planet), planet_topic(planet), {:planet_signal, signal})

    signal
  end

  @doc """
  Stops one planet relay to simulate a node outage.
  """
  @spec stop_planet(atom()) :: :ok
  def stop_planet(planet) do
    planet
    |> planet_relay_name()
    |> GenServer.stop(:normal)
  end

  @doc """
  Returns the PubSub server name for a planet-local bus.
  """
  @spec planet_bus_name(atom()) :: atom()
  def planet_bus_name(:mars), do: SignalNetwork.MarsBus
  def planet_bus_name(:deimos), do: SignalNetwork.DeimosBus

  @doc """
  Returns the topic used on a planet-local bus.
  """
  @spec planet_topic(atom()) :: String.t()
  def planet_topic(planet), do: "planet:#{planet}:signals"

  @doc """
  Returns the relay process name for a planet.
  """
  @spec planet_relay_name(atom()) :: atom()
  def planet_relay_name(:mars), do: SignalNetwork.MarsRelay
  def planet_relay_name(:deimos), do: SignalNetwork.DeimosRelay

  defp runtime_signal(attrs) do
    attrs
    |> Map.put_new(:tick, System.unique_integer([:positive, :monotonic]))
    |> Signal.new!()
  end
end
