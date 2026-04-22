defmodule SignalNetwork.ControlRoom do
  @moduledoc """
  A tiny live projection that listens to every signal on the bus.

  The control room replaces repeated polling with subscription: when signals
  arrive, the latest view updates itself.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SignalNetwork.Signal

  @type state :: %{optional(String.t()) => Signal.t()}

  @doc """
  Starts the control-room projection.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc """
  Returns the latest view known to the control room.
  """
  @spec snapshot() :: state()
  def snapshot do
    GenServer.call(__MODULE__, :snapshot)
  end

  @doc """
  Clears the live view back to an empty projection.
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
  def handle_call(:snapshot, _from, state), do: {:reply, state, state}

  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{}}

  @impl true
  def handle_info(%Signal{} = signal, state) do
    {:noreply, Map.put(state, signal.topic, signal)}
  end
end
