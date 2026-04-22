defmodule SignalNetworkTest do
  use ExUnit.Case
  doctest SignalNetwork

  import Phoenix.ChannelTest

  @endpoint SignalNetwork.Web.Endpoint

  setup do
    SignalNetwork.reset_runtime!()
    :ok
  end

  test "polling still goes stale between requests" do
    story = SignalNetwork.bootstrap_story!()

    assert story.first_snapshot.latest_by_topic["alerts:mars"] == nil
    assert story.refreshed_snapshot.latest_by_topic["alerts:mars"].event == :oxygen_low
  end

  test "presence shows both operators and connected systems" do
    {:ok, _meta} =
      SignalNetwork.track_system("mars-colony-core", %{kind: "life-support", online: true})

    {:ok, _, _socket} =
      socket(SignalNetwork.Web.UserSocket, "operator-1", %{operator: "navy"})
      |> subscribe_and_join(SignalNetwork.Web.OperatorChannel, SignalNetwork.channel_topic())

    assert_push("snapshot", %{latest_by_topic: %{}})
    assert_push("presence_state", %{operators: operators, systems: systems})

    assert Map.has_key?(operators, "navy")
    assert Map.has_key?(systems, "mars-colony-core")
  end
end
