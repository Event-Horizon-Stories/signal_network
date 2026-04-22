defmodule SignalNetwork.Application do
  @moduledoc """
  Starts the lesson application.

  Lesson 1 does not need runtime processes yet, but keeping the supervision tree
  in place makes later chapters cumulative instead of structural rewrites.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: SignalNetwork.pubsub_name()},
      SignalNetwork.Consumers.ControlRoom,
      SignalNetwork.Consumers.AlertSink,
      SignalNetwork.Consumers.AnalyticsSink,
      SignalNetwork.Web.Endpoint,
      SignalNetwork.Web.ChannelBridge
    ]

    opts = [strategy: :one_for_one, name: SignalNetwork.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
