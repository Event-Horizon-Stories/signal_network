defmodule SignalNetwork.PartitionTracker do
  @moduledoc """
  Detects sequence gaps after a source reconnects.

  PubSub can tell us that a later signal arrived. It cannot replay the ones that
  never reached the subscriber.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SignalNetwork.Signal

  @doc """
  Starts the partition tracker.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{last_seen: %{}, gaps: []},
      Keyword.put_new(opts, :name, __MODULE__)
    )
  end

  @doc """
  Returns the known gaps, oldest first.
  """
  @spec gaps() :: [map()]
  def gaps do
    gaps(:all)
  end

  @doc """
  Returns the known gaps, optionally filtered to one source.
  """
  @spec gaps(:all | atom()) :: [map()]
  def gaps(source) do
    GenServer.call(__MODULE__, {:gaps, source})
  end

  @doc """
  Clears all tracked sequence data.
  """
  @spec reset() :: :ok
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def init(state) do
    :ok = PubSub.subscribe(SignalNetwork.pubsub_name(), SignalNetwork.control_room_topic())
    {:ok, state}
  end

  @impl true
  def handle_call({:gaps, :all}, _from, state), do: {:reply, Enum.reverse(state.gaps), state}

  def handle_call({:gaps, source}, _from, state) do
    gaps = Enum.filter(Enum.reverse(state.gaps), &(&1.source == source))
    {:reply, gaps, state}
  end

  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{last_seen: %{}, gaps: []}}

  @impl true
  def handle_info(%Signal{sequence: nil}, state), do: {:noreply, state}

  def handle_info(%Signal{} = signal, state) do
    last_sequence = Map.get(state.last_seen, signal.source)

    {last_seen, gaps} =
      case last_sequence do
        nil ->
          {Map.put(state.last_seen, signal.source, signal.sequence), state.gaps}

        previous when signal.sequence == previous + 1 ->
          {Map.put(state.last_seen, signal.source, signal.sequence), state.gaps}

        previous when signal.sequence > previous + 1 ->
          gap = %{
            source: signal.source,
            missed_sequences: Enum.to_list((previous + 1)..(signal.sequence - 1))
          }

          {Map.put(state.last_seen, signal.source, signal.sequence), [gap | state.gaps]}

        _previous ->
          {state.last_seen, state.gaps}
      end

    {:noreply, %{state | last_seen: last_seen, gaps: gaps}}
  end
end
