defmodule SignalNetwork.Network.PlanetRelay do
  @moduledoc """
  Bridges a planet-local bus into the shared network bus.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SignalNetwork.Signals.Signal

  @doc """
  Starts one relay for a named planet.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    planet = Keyword.fetch!(opts, :planet)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, %{planet: planet}, name: name)
  end

  @impl true
  def init(%{planet: planet} = state) do
    :ok =
      PubSub.subscribe(SignalNetwork.planet_bus_name(planet), SignalNetwork.planet_topic(planet))

    {:ok, state}
  end

  @impl true
  def handle_info({:planet_signal, %Signal{} = signal}, state) do
    :ok = SignalNetwork.Network.StormGate.dispatch(signal)
    {:noreply, state}
  end
end
