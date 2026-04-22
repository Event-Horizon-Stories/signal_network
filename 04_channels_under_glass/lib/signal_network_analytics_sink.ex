defmodule SignalNetwork.AnalyticsSink do
  @moduledoc """
  Counts how often the network sees each event name.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SignalNetwork.Signal

  @doc """
  Starts the analytics sink.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc """
  Returns the event counters.
  """
  @spec counts() :: %{optional(atom()) => non_neg_integer()}
  def counts do
    GenServer.call(__MODULE__, :counts)
  end

  @doc """
  Clears the analytics counters.
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
  def handle_call(:counts, _from, state), do: {:reply, state, state}

  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{}}

  @impl true
  def handle_info(%Signal{} = signal, state) do
    {:noreply, Map.update(state, signal.event, 1, &(&1 + 1))}
  end
end
