defmodule SignalNetwork.Network.PriorityRouter do
  @moduledoc """
  Broadcasts each signal to both its domain topic and a priority feed.
  """

  alias Phoenix.PubSub
  alias SignalNetwork.Signals.Signal

  @doc """
  Publishes a signal onto the shared bus.
  """
  @spec dispatch(Signal.t()) :: :ok
  def dispatch(%Signal{} = signal) do
    :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), signal.topic, signal)

    :ok =
      PubSub.broadcast(
        SignalNetwork.pubsub_name(),
        SignalNetwork.priority_topic(signal.priority),
        signal
      )

    :ok =
      PubSub.broadcast(SignalNetwork.pubsub_name(), SignalNetwork.control_room_topic(), signal)
  end
end
