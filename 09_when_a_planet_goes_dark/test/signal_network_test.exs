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

  test "a reconnect can reveal missing sequences without recovering them" do
    SignalNetwork.announce(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 94},
      sequence: 1
    })

    SignalNetwork.announce(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 92},
      sequence: 2
    })

    SignalNetwork.announce(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 81},
      sequence: 5
    })

    assert [%{source: :mars_colony, missed_sequences: [3, 4]}] = SignalNetwork.gaps()
    assert SignalNetwork.dashboard_snapshot()["telemetry:mars"].payload.percent == 81
  end
end
