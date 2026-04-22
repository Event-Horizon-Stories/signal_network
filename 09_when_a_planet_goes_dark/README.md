# Lesson 09: When A Planet Goes Dark

Here the wire tells the truth about its own limits.

Up to this point, the network has learned how to listen, fan out, push to clients, survive overload, and speak with clearer urgency. None of that makes the wire durable. The harshest lesson in the series is not that PubSub is weak. It is that PubSub is honest about what it is for.

A reconnecting planet can prove that something was missed. It cannot, by PubSub alone, recover what those missed signals were.

Interactive companion: [`../livebooks/09_when_a_planet_goes_dark.livemd`](../livebooks/09_when_a_planet_goes_dark.livemd)

## What You'll Learn

- how to tag signals with source-local sequence numbers
- how to detect a delivery gap after a source reconnects
- why PubSub is distribution, not persistence
- how to describe missing history without inventing a replay path that does not exist

## The Story

Mars falls quiet. Not gracefully, not with a tidy shutdown event, but with the kind of absence that turns every healthy signal around it into a sharper accusation.

When it returns, the next telemetry signal carries sequence `5`. Mission control remembers seeing `2`. That is enough to know the network missed `3` and `4`. The shape of the loss becomes visible the moment the source speaks again.

What the network still cannot do is recover those missing messages. It can measure the wound. It cannot yet heal it.

## The PubSub Concept

This chapter teaches the edge of PubSub.

PubSub can:

- deliver a signal that arrives
- let consumers react immediately

PubSub cannot:

- replay the signals a disconnected subscriber never saw
- reconstruct payloads that were never persisted anywhere else

`SignalNetwork.Network.PartitionTracker` makes that limitation visible by tracking sequence gaps instead of pretending the wire is durable.

## What We're Building

This lesson keeps the priority router and adds:

- an optional `sequence` field on `SignalNetwork.Signals.Signal`
- `SignalNetwork.Network.PartitionTracker`
- `SignalNetwork.gaps/0`

That is enough to detect missing delivery without yet solving it.

## The Code

The gap detection lives in:

- [`lib/signals/signal.ex`](./lib/signals/signal.ex)
- [`lib/network/partition_tracker.ex`](./lib/network/partition_tracker.ex)
- [`lib/signal_network.ex`](./lib/signal_network.ex)

The crucial branch is the reconnect gap:

```elixir
previous when signal.sequence > previous + 1 ->
  gap = %{source: signal.source, missed_sequences: Enum.to_list((previous + 1)..(signal.sequence - 1))}
  {Map.put(state.last_seen, signal.source, signal.sequence), [gap | state.gaps]}
```

The tracker records what is missing. It does not fake a recovery path.

## Trying It Out

Run the lesson:

```bash
cd 09_when_a_planet_goes_dark
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()

for {sequence, percent} <- [{1, 94}, {2, 92}, {5, 81}] do
  SignalNetwork.announce(%{
    source: :mars_colony,
    topic: "telemetry:mars",
    event: :oxygen_level,
    payload: %{percent: percent},
    sequence: sequence
  })
end

%{
  gaps: SignalNetwork.gaps(),
  latest_live_value: SignalNetwork.dashboard_snapshot()["telemetry:mars"]
}
```

## What the Tests Prove

The tests prove that:

- the gap tracker records missing sequences `[3, 4]`
- the latest live value still updates correctly
- earlier layers of the app remain intact

The network can now admit uncertainty honestly.

## Why This Matters

This is the chapter where PubSub stops being mistaken for a full event history.

If you need recovery, auditing, or replay, you need another system besides the wire.

## PubSub Takeaway

PubSub is about live delivery, not durable memory.

A gap detector is useful because it tells you exactly when you have reached that boundary.

## What Still Hurts

Mission control can name the missing sequences now, but it still cannot read them.

The story needs history, not just an admission of loss.

## Next Lesson

In lesson 10, a journaled event path joins the live bus so the network can replay what PubSub alone could never recover.
