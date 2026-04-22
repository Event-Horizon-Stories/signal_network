# Lesson 01: Polling The Void

Mission control begins in the oldest possible posture: ask every source what the world looks like right now, then ask again a moment later.

The answer is never wrong for long. It is simply late.

Interactive companion: [`../livebooks/01_polling_the_void.livemd`](../livebooks/01_polling_the_void.livemd)

## What You'll Learn

- how to model a network as an append-only signal history
- how to reduce that history into a point-in-time dashboard snapshot
- why polling cost scales with the number of sources, not with the amount of change
- how snapshots go stale the moment a new signal arrives

## The Story

Mars habitat telemetry is drifting in from one side of the system. A shipment to Deimos has already left dock. An orbital ship has checked in.

Mission control wants one answer:

What is the current state?

The dashboard can get that answer, but only by walking the network source by source. It reads Mars. It reads the trade authority. It reads the ship. Then it freezes that answer into a snapshot that starts aging immediately.

## The PubSub Concept

The first PubSub lesson is that polling is the shape PubSub replaces.

There is no subscription here yet. The dashboard calls `SignalNetwork.poll_dashboard/2`, and that function asks the world to reread every source before it can return a `SignalNetwork.Snapshot`.

That gives us a clean baseline:

- a signal history
- a reduced view
- explicit read cost

In the next chapter, the signal struct survives. The request path does not.

## What We're Building

This lesson creates:

- a `SignalNetwork.Signal` struct for the events crossing the universe
- a `SignalNetwork.World` struct that stores signal history
- a `SignalNetwork.Snapshot` struct for polled dashboard views
- a `SignalNetwork.bootstrap_story!/0` helper that demonstrates stale data directly

## The Code

The lesson lives in:

- [`lib/signal_network.ex`](./lib/signal_network.ex)
- [`lib/signal_network_signal.ex`](./lib/signal_network_signal.ex)
- [`lib/signal_network_world.ex`](./lib/signal_network_world.ex)
- [`lib/signal_network_snapshot.ex`](./lib/signal_network_snapshot.ex)

The core polling path is small and expensive in exactly the way we need:

```elixir
def poll_dashboard(%__MODULE__{} = world, dashboard_id) do
  remote_reads =
    world.signals
    |> Enum.map(& &1.source)
    |> Enum.uniq()
    |> length()

  %Snapshot{
    dashboard_id: dashboard_id,
    captured_at_tick: world.next_tick - 1,
    latest_by_topic: current_state(world),
    remote_reads: remote_reads
  }
end
```

The dashboard gets a useful answer, but it pays one read per source every time.

## Trying It Out

Run the lesson:

```bash
cd 01_polling_the_void
mix test
iex -S mix
```

Then paste:

```elixir
story = SignalNetwork.bootstrap_story!()

%{
  first_topics: Map.keys(story.first_state),
  stale_alert: story.stale_snapshot.latest_by_topic["alerts:mars"],
  refreshed_alert: story.refreshed_snapshot.latest_by_topic["alerts:mars"],
  remote_reads: story.first_snapshot.remote_reads
}
```

You should see that the stale snapshot has no Mars alert, while the refreshed snapshot does.

## What the Tests Prove

The tests prove two things:

- a snapshot becomes stale as soon as a later signal arrives
- polling cost grows when another source joins the network

That second point matters. Polling cost is tied to topology, not to change.

## Why This Matters

REST-trained intuition says the dashboard should ask for what it needs.

This chapter shows the cost of that instinct in a signal-heavy system. The control room is forced to do repeated work even when the world is quiet, and it is still behind the moment the answer is returned.

## PubSub Takeaway

Before PubSub can feel necessary, polling has to feel inadequate.

This chapter gives you the baseline failure: the dashboard asks, pays, and still falls behind.

## What Still Hurts

Nothing announces itself yet.

The dashboard only changes when someone remembers to poll again, and every poll rereads the same universe from scratch.

## Next Lesson

In lesson 2, the network stops waiting for requests and starts broadcasting signals over Phoenix PubSub.
