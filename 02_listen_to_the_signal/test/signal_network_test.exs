defmodule SignalNetworkTest do
  use ExUnit.Case
  doctest SignalNetwork

  setup do
    SignalNetwork.reset_runtime!()
    :ok
  end

  test "polling still goes stale between requests" do
    story = SignalNetwork.bootstrap_story!()

    assert story.first_snapshot.latest_by_topic["alerts:mars"] == nil
    assert story.refreshed_snapshot.latest_by_topic["alerts:mars"].event == :oxygen_low
  end

  test "subscribers receive live signals without asking" do
    SignalNetwork.listen("alerts:mars")

    signal =
      SignalNetwork.announce(%{
        source: :mars_colony,
        topic: "alerts:mars",
        event: :reactor_unstable,
        payload: %{sector: "reactor-ring", variance: 12}
      })

    assert_receive %SignalNetwork.Signals.Signal{event: :reactor_unstable} = received
    assert received == signal
  end

  test "the control room keeps the latest live state projection" do
    SignalNetwork.announce(%{
      source: :trade_authority,
      topic: "trade:shipment-17",
      event: :shipment_arrived,
      payload: %{status: "arrived", destination: "deimos"}
    })

    assert SignalNetwork.dashboard_snapshot()["trade:shipment-17"].event == :shipment_arrived
  end
end
