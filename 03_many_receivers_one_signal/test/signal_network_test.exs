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

  test "one signal fans out to multiple subscribers" do
    SignalNetwork.listen("trade:shipment-17")

    signal =
      SignalNetwork.announce(%{
        source: :trade_authority,
        topic: "trade:shipment-17",
        event: :shipment_delayed,
        payload: %{status: "delayed", reason: "solar winds", minutes: 42}
      })

    assert_receive %SignalNetwork.Signal{event: :shipment_delayed}
    assert SignalNetwork.dashboard_snapshot()["trade:shipment-17"] == signal
    assert [^signal] = SignalNetwork.alerts()
    assert SignalNetwork.analytics() == %{shipment_delayed: 1}
  end
end
