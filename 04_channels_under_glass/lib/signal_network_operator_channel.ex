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
    push(socket, "snapshot", %{latest_by_topic: SignalNetwork.dashboard_snapshot()})
    {:noreply, socket}
  end
end
