defmodule SignalNetwork.OperatorChannel do
  @moduledoc """
  Streams control-room signals to connected operators.
  """

  use Phoenix.Channel

  @impl true
  def join("operations:mission-control", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def join("operations:" <> _rest, _payload, _socket) do
    {:error, %{reason: "unknown control room"}}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _meta} =
      SignalNetwork.Presence.track(
        self(),
        socket.topic,
        socket.assigns.operator,
        %{role: "operator", joined_via: "channel"}
      )

    push(socket, "snapshot", %{latest_by_topic: SignalNetwork.dashboard_snapshot()})

    push(socket, "presence_state", %{
      operators: SignalNetwork.operators_online(),
      systems: SignalNetwork.systems_online()
    })

    {:noreply, socket}
  end
end
