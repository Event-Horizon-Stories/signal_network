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

  test "low-priority storms get trimmed while critical signals still pass" do
    for minute <- 1..5 do
      SignalNetwork.announce(%{
        source: :orbital_ship_7,
        topic: "trade:shipment-17",
        event: :shipment_ping,
        payload: %{minute: minute},
        priority: :low
      })
    end

    SignalNetwork.announce(%{
      source: :mars_colony,
      topic: "alerts:mars",
      event: :reactor_unstable,
      payload: %{variance: 19},
      priority: :high
    })

    assert length(SignalNetwork.dropped_signals()) >= 2
    assert SignalNetwork.dashboard_snapshot()["alerts:mars"].event == :reactor_unstable
  end
end
