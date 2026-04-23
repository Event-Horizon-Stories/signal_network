# Lesson 04: Channels Under Glass

Mission control finally gets a real viewing window.

Up to now the live network has mostly been something the BEAM could feel from the inside. Signals were moving, sinks were reacting, projections were changing, but the human edge of the story was still standing outside the glass. Here, that glass opens.

Operators do not refresh the dashboard anymore. They join once, and the network pushes changes as they happen.

Interactive companion: [`../livebooks/04_channels_under_glass.livemd`](../livebooks/04_channels_under_glass.livemd)

## What Changes

- how Phoenix Channels turn server-side PubSub updates into client pushes
- how to join a topic-based operator feed
- how to send an initial snapshot and then stream live events afterwards
- how channels sit on top of the same PubSub bus instead of replacing it

## The Story

The control room is alive now, but only inside the BEAM. Processes can hear the signal. Internal projections can stay current. That is useful, but it is not yet a working operations room.

Operators need a surface they can keep open while signals fly. They need the current picture the moment they enter the room, not after another request cycle. They need the next alert to strike the screen as soon as it crosses the wire.

So the network adds a channel under glass. The bus stays the same. The audience changes. The story finally reaches the people who have to live inside it.

## Under The Hood

Phoenix Channels are not a different distribution model from PubSub. They are a client-facing edge built on top of it.

In this lesson:

- PubSub still carries the internal signal
- `SignalNetwork.Web.ChannelBridge` listens to the shared bus
- `SignalNetwork.Web.OperatorChannel` pushes a snapshot on join
- later signals are pushed as `"signal"` events to connected clients

That is the shape you want to recognize: PubSub inside, channel at the boundary.

## Network Changes

Everything from the earlier network stays in place, and the client edge adds:

- `SignalNetwork.Web.Endpoint`
- `SignalNetwork.Web.UserSocket`
- `SignalNetwork.Web.OperatorChannel`
- `SignalNetwork.Web.ChannelBridge`

The producers still call `SignalNetwork.announce/1`. Only the outer surface changes.

## The Code

The channel bridge and join path live in:

- [`lib/web/channel_bridge.ex`](./lib/web/channel_bridge.ex)
- [`lib/web/operator_channel.ex`](./lib/web/operator_channel.ex)
- [`lib/web/user_socket.ex`](./lib/web/user_socket.ex)
- [`test/signal_network_test.exs`](./test/signal_network_test.exs)

The join callback sends the current state immediately:

```elixir
def handle_info(:after_join, socket) do
  push(socket, "snapshot", %{latest_by_topic: SignalNetwork.dashboard_snapshot()})
  {:noreply, socket}
end
```

That gives a newly connected operator context before the next live event arrives.

## Trying It Out

Run the chapter:

```bash
cd 04_channels_under_glass
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()

SignalNetwork.announce(%{
  source: :trade_authority,
  topic: "trade:shipment-17",
  event: :shipment_delayed,
  payload: %{status: "delayed", reason: "solar winds", minutes: 42}
})

%{
  channel_topic: SignalNetwork.channel_topic(),
  live_state: SignalNetwork.dashboard_snapshot()["trade:shipment-17"]
}
```

The test suite is the best place to watch the actual channel push, because it joins the socket and asserts the `"snapshot"` and `"signal"` events directly.

## What the Tests Prove

The tests prove that:

- earlier polling behavior still exists
- a channel join receives the current snapshot
- a later broadcast becomes a pushed `"signal"` event

The operator dashboard is no longer a poller. It is a subscriber with a websocket boundary.

## Why This Matters

Real-time UI is not a separate architecture from PubSub. It is one more consumer, with tighter latency expectations and a network boundary in front of it.

Once that clicks, channels feel less mysterious. They are simply a way to keep listening from outside the server.

## What Holds

Channels are how PubSub reaches people.

The wire stays event-driven all the way to the client edge.

## What Still Hurts

A connected dashboard still does not know who else is in the room or which systems are online.

The wire is live, but the network has no coordination surface yet.

## Next Shift

In [`05_presence_in_mission_control`](../05_presence_in_mission_control/README.md), mission control learns operator and system presence so the network can see who is actually on the wire.
