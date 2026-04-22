# Lesson 10: History And Signal Together

The network is finally complete enough to answer both operational questions:

- what is happening right now?
- what happened while I was gone?

Live delivery answers the first. History answers the second.

This final chapter matters because the series has spent nine lessons refusing to blur those responsibilities together. The wire has been allowed to be fast, immediate, and forgetful. Now it finally meets the thing that can remember what it was never designed to keep.

Interactive companion: [`../livebooks/10_history_and_signal_together.livemd`](../livebooks/10_history_and_signal_together.livemd)

## What Changes

- how to add a journaled event path alongside live PubSub delivery
- how to append signals durably without broadcasting them yet
- how to replay missing sequences from the journal after a gap is detected
- how PubSub and event history complement rather than replace each other

## The Story

Mars returns to the wire after a dark stretch.

Mission control already knows sequences `3` and `4` were missed. That knowledge alone was painful in the previous chapter, because it proved loss without offering relief. This time the story changes. While the live subscriber was cut off, the missing signals were still written into a journal. The wire kept doing what wires do: it delivered only to the listeners that were present. The journal did what history does: it kept faith with events that deserved to outlive the moment they first occurred.

That is the final movement of the series. The network does not stop being live. It stops pretending that live is enough.

## Under The Hood

This chapter closes the loop by refusing to ask PubSub to be something it is not.

The final design separates two jobs:

- `record_and_announce/1` writes a signal to the journal and then sends it live
- `journal_signal/1` writes history without assuming live delivery happened
- `recover_gap/1` reads the missing sequences back from the journal

That is the full picture:

- PubSub for live reaction
- journal for replay and audit

## Network Changes

Every earlier layer stays in place, and the network adds:

- `SignalNetwork.History.EventJournal`
- `SignalNetwork.journal_signal/1`
- `SignalNetwork.record_and_announce/1`
- `SignalNetwork.recover_gap/1`

The signal bus still matters. It is simply no longer the only keeper of truth.

## The Code

The history layer lives in:

- [`lib/history/event_journal.ex`](./lib/history/event_journal.ex)
- [`lib/signal_network.ex`](./lib/signal_network.ex)
- [`lib/network/partition_tracker.ex`](./lib/network/partition_tracker.ex)

The final integration path is the important one:

```elixir
def record_and_announce(attrs) do
  signal = journal_signal(attrs)
  :ok = StormGate.dispatch(signal)
  signal
end
```

History is written first. Live delivery follows.

## Trying It Out

Run the chapter:

```bash
cd 10_history_and_signal_together
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()

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

%{
  gaps: SignalNetwork.gaps(),
  recovered: SignalNetwork.recover_gap(:mars_colony)
}
```

## What the Tests Prove

The tests prove that:

- the journal retains sequences `3` and `4`
- `recover_gap/1` can return those missing records after sequence `5` arrives live
- the current control-room view still reflects the live tip of the stream

The system finally has both live reaction and usable memory.

## Why This Matters

This is the chapter where the architecture stops arguing with reality.

The wire is fast but forgetful. History is slower but durable. Together they form a trustworthy system.

## What Holds

PubSub is strongest when it is paired with the right neighbor.

Use the bus for immediacy. Use the journal for truth that needs to outlive a connection.

## What Still Hurts

The core series ends here, but the network could still go further into real cluster discovery, external event stores, richer clients, and replayable projections.

Those are natural extensions precisely because the boundary between live delivery and durable history is now clear.

## Where The Series Could Go Next

The next serious extensions would be:

- a real distributed Erlang cluster with node discovery
- an external event store instead of the in-memory journal
- richer operator clients using LiveView or browser dashboards
- replayable projections built from the journal instead of only the live control-room view
