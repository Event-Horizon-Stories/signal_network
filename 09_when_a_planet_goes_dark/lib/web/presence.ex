defmodule SignalNetwork.Web.Presence do
  @moduledoc """
  Tracks which operators and systems are online.
  """

  use Phoenix.Presence,
    otp_app: :signal_network,
    pubsub_server: SignalNetwork.pubsub_name()
end
