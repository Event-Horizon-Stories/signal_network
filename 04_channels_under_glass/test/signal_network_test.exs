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

  test "the channel pushes a snapshot on join and live signals afterwards" do
    {:ok, _, socket} =
      SignalNetwork.Web.UserSocket
      |> socket("operator-1", %{})
      |> subscribe_and_join(SignalNetwork.Web.OperatorChannel, SignalNetwork.channel_topic(), %{
        "operator" => "navy"
      })

    assert_push("snapshot", %{latest_by_topic: %{}})

    SignalNetwork.announce(%{
      source: :trade_authority,
      topic: "trade:shipment-17",
      event: :shipment_delayed,
      payload: %{status: "delayed", reason: "solar winds", minutes: 42}
    })

    assert_broadcast("signal", %{
      topic: "trade:shipment-17",
      event: :shipment_delayed,
      payload: %{status: "delayed", reason: "solar winds", minutes: 42}
    })

    assert socket.topic == SignalNetwork.channel_topic()
  end
end
