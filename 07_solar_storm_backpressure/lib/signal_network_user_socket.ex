defmodule SignalNetwork.UserSocket do
  @moduledoc """
  The websocket entry point for operator clients.
  """

  use Phoenix.Socket

  channel("operations:*", SignalNetwork.OperatorChannel)

  @impl true
  def connect(%{"operator" => operator}, socket, _connect_info) do
    {:ok, assign(socket, :operator, operator)}
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "operators:#{socket.assigns.operator}"
end
