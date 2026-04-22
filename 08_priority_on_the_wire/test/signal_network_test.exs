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

  test "signals land on both their domain topic and their priority feed" do
    SignalNetwork.listen_priority(:high)
    SignalNetwork.listen_priority(:low)

    SignalNetwork.announce(%{
      source: :trade_authority,
      topic: "trade:shipment-17",
      event: :shipment_delayed,
      payload: %{status: "delayed"},
      priority: :low
    })

    SignalNetwork.announce(%{
      source: :mars_colony,
      topic: "alerts:mars",
      event: :reactor_failure,
      payload: %{sector: "ring-2"},
      priority: :high
    })

    assert_receive %SignalNetwork.Signal{event: :shipment_delayed, priority: :low}
    assert_receive %SignalNetwork.Signal{event: :reactor_failure, priority: :high}

    assert SignalNetwork.dashboard_snapshot()["alerts:mars"].event == :reactor_failure
  end
end
