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

  test "the journal can recover the signals PubSub could not replay" do
    SignalNetwork.record_and_announce(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 94},
      sequence: 1
    })

    SignalNetwork.record_and_announce(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 92},
      sequence: 2
    })

    SignalNetwork.journal_signal(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 89},
      sequence: 3
    })

    SignalNetwork.journal_signal(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 86},
      sequence: 4
    })

    SignalNetwork.record_and_announce(%{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :oxygen_level,
      payload: %{percent: 81},
      sequence: 5
    })

    recovered = SignalNetwork.recover_gap(:mars_colony)

    assert Enum.map(recovered, & &1.sequence) == [3, 4]
    assert Enum.map(recovered, & &1.payload.percent) == [89, 86]
    assert SignalNetwork.dashboard_snapshot()["telemetry:mars"].payload.percent == 81
  end
end
