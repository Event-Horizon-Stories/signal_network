defmodule SignalNetwork.Signals.World do
  @moduledoc """
  The fragile universe that the polling dashboard is trying to understand.

  The world only knows how to append signals and reduce them into the newest
  state per topic. The polling cost comes from asking the world to reread every
  source on each request.
  """

  alias SignalNetwork.{Signals.Signal, Signals.Snapshot}

  @enforce_keys [:signals, :next_tick]
  defstruct [:signals, :next_tick]

  @type t :: %__MODULE__{
          signals: [Signal.t()],
          next_tick: pos_integer()
        }

  @doc """
  Creates a world from an existing signal history.
  """
  @spec new([Signal.t()]) :: t()
  def new(signals) do
    last_tick =
      signals
      |> Enum.map(& &1.tick)
      |> Enum.max(fn -> 0 end)

    %__MODULE__{signals: signals, next_tick: last_tick + 1}
  end

  @doc """
  Emits a new signal at the next world tick.
  """
  @spec emit(t(), map()) :: t()
  def emit(%__MODULE__{} = world, attrs) do
    signal = Signal.new!(Map.put_new(attrs, :tick, world.next_tick))

    %{world | signals: world.signals ++ [signal], next_tick: signal.tick + 1}
  end

  @doc """
  Reduces the signal history into the latest event seen for each topic.
  """
  @spec current_state(t()) :: %{optional(String.t()) => Signal.t()}
  def current_state(%__MODULE__{} = world) do
    Enum.reduce(world.signals, %{}, fn signal, acc ->
      Map.put(acc, signal.topic, signal)
    end)
  end

  @doc """
  Polls every known source and returns a point-in-time dashboard snapshot.

  The `remote_reads` count is intentionally equal to the number of distinct
  signal sources. Polling cost scales with the size of the network, not with the
  amount of change.
  """
  @spec poll_dashboard(t(), String.t()) :: Snapshot.t()
  def poll_dashboard(%__MODULE__{} = world, dashboard_id) do
    remote_reads =
      world.signals
      |> Enum.map(& &1.source)
      |> Enum.uniq()
      |> length()

    %Snapshot{
      dashboard_id: dashboard_id,
      captured_at_tick: world.next_tick - 1,
      latest_by_topic: current_state(world),
      remote_reads: remote_reads
    }
  end
end
