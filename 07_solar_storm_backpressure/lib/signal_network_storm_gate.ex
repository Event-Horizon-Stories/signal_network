defmodule SignalNetwork.StormGate do
  @moduledoc """
  Filters bursts of low-priority traffic before they reach the shared bus.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SignalNetwork.Signal

  @window_ms 100
  @max_low_priority 3

  @doc """
  Starts the storm gate.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      %{recent: [], dropped: []},
      Keyword.put_new(opts, :name, __MODULE__)
    )
  end

  @doc """
  Dispatches a signal, dropping low-priority chatter when the storm window is saturated.
  """
  @spec dispatch(Signal.t()) :: :ok
  def dispatch(signal) do
    GenServer.call(__MODULE__, {:dispatch, signal})
  end

  @doc """
  Returns the dropped signals, oldest first.
  """
  @spec dropped_signals() :: [Signal.t()]
  def dropped_signals do
    GenServer.call(__MODULE__, :dropped_signals)
  end

  @doc """
  Clears the storm history.
  """
  @spec reset() :: :ok
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:dropped_signals, _from, state) do
    {:reply, Enum.reverse(state.dropped), state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{recent: [], dropped: []}}
  end

  def handle_call({:dispatch, %Signal{} = signal}, _from, state) do
    now = System.monotonic_time(:millisecond)
    recent = Enum.filter(state.recent, &(now - &1 < @window_ms))

    if signal.priority == :low and length(recent) >= @max_low_priority do
      {:reply, :ok, %{state | recent: recent, dropped: [signal | state.dropped]}}
    else
      :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), signal.topic, signal)

      :ok =
        PubSub.broadcast(SignalNetwork.pubsub_name(), SignalNetwork.control_room_topic(), signal)

      {:reply, :ok, %{state | recent: [now | recent]}}
    end
  end
end
