defmodule SignalNetwork.Endpoint do
  @moduledoc """
  Minimal Phoenix endpoint for channel-based operator dashboards.
  """

  use Phoenix.Endpoint, otp_app: :signal_network

  socket("/socket", SignalNetwork.UserSocket,
    websocket: true,
    longpoll: false
  )

  def render(_template, _assigns) do
    %{error: "signal network error"}
  end
end
