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

  alias SignalNetwork.{Signals.Signal, Signals.World}

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
  Builds the full lesson narrative in one inspectable map.

  The returned structure is used by the README examples, the test suite, and
  the Livebook companion.
  """
  @spec bootstrap_story!() :: map()
  def bootstrap_story! do
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

    %{
      world: world_after_alert,
      first_snapshot: first_snapshot,
      stale_snapshot: first_snapshot,
      refreshed_snapshot: refreshed_snapshot,
      first_state: first_snapshot.latest_by_topic,
      refreshed_state: refreshed_snapshot.latest_by_topic
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
end
