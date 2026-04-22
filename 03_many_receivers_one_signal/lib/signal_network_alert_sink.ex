defmodule SignalNetwork.AlertSink do
  @moduledoc """
  Receives high-signal operational events that need immediate attention.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SignalNetwork.Signal

  @doc """
  Starts the alert sink.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc """
  Returns the alert notifications in arrival order.
  """
  @spec notifications() :: [Signal.t()]
  def notifications do
    GenServer.call(__MODULE__, :notifications)
  end

  @doc """
  Clears the alert sink.
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
  def handle_call(:notifications, _from, state), do: {:reply, Enum.reverse(state), state}

  def handle_call(:reset, _from, _state), do: {:reply, :ok, []}

  @impl true
  def handle_info(%Signal{} = signal, state) do
    state =
      if String.starts_with?(signal.topic, "alerts:") or signal.event == :shipment_delayed do
        [signal | state]
      else
        state
      end

    {:noreply, state}
  end
end
