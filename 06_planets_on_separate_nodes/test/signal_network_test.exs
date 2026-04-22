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

  test "planet relays feed the shared control room" do
    SignalNetwork.announce_from_planet(:mars, %{
      source: :mars_colony,
      topic: "telemetry:mars",
      event: :energy_level,
      payload: %{percent: 68}
    })

    assert eventually(fn ->
             snapshot = SignalNetwork.dashboard_snapshot()
             snapshot["telemetry:mars"] && snapshot["telemetry:mars"].payload.percent == 68
           end)
  end

  test "other planets keep flowing when one relay goes down" do
    SignalNetwork.stop_planet(:mars)

    SignalNetwork.announce_from_planet(:deimos, %{
      source: :deimos_station,
      topic: "alerts:deimos",
      event: :dock_pressure_drop,
      payload: %{sector: "dock-4", delta: 11}
    })

    assert eventually(fn ->
             snapshot = SignalNetwork.dashboard_snapshot()
             snapshot["alerts:deimos"] && snapshot["alerts:deimos"].event == :dock_pressure_drop
           end)
  end

  defp eventually(fun, attempts \\ 20)

  defp eventually(fun, attempts) when attempts > 0 do
    if fun.() do
      true
    else
      Process.sleep(10)
      eventually(fun, attempts - 1)
    end
  end

  defp eventually(_fun, 0), do: false
end
