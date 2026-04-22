defmodule SignalNetworkTest do
  use ExUnit.Case
  doctest SignalNetwork

  test "polling returns a point-in-time snapshot that goes stale immediately" do
    story = SignalNetwork.bootstrap_story!()

    assert story.first_snapshot.remote_reads == 3
    assert story.first_snapshot.latest_by_topic["alerts:mars"] == nil

    assert story.stale_snapshot.latest_by_topic["alerts:mars"] == nil

    assert story.refreshed_snapshot.latest_by_topic["alerts:mars"].event == :oxygen_low
    assert story.refreshed_snapshot.latest_by_topic["alerts:mars"].payload.percent == 18
  end

  test "polling cost scales with the number of signal sources" do
    world =
      SignalNetwork.new_world()
      |> SignalNetwork.emit(%{
        source: :deimos_station,
        topic: "telemetry:deimos",
        event: :energy_level,
        payload: %{percent: 63}
      })

    snapshot = SignalNetwork.poll_dashboard(world, dashboard_id: "ops")

    assert snapshot.remote_reads == 4
  end
end
