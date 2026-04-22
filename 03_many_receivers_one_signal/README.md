# Lesson 03: Many Receivers, One Signal

One delayed shipment is enough to light three different consoles.

That is when PubSub starts to feel bigger than convenience. A single event crosses the wire, and three different parts of the system lean toward it for different reasons. Mission control wants visibility. Alerting wants urgency. Analytics wants memory. The producer should not have to split itself three ways just because the consequences travel farther than the source.

Interactive companion: [`../livebooks/03_many_receivers_one_signal.livemd`](../livebooks/03_many_receivers_one_signal.livemd)

## What Changes

- how PubSub fan-out lets one event drive many reactions
- how to keep multiple consumers independent from one another
- how to add new subscribers without changing the producer API
- how to preserve earlier polling and live-projection behavior while the network grows

## The Story

A shipment bound for Deimos slows under solar winds. It is one delay in one corridor of space, but the moment it becomes real, it begins casting different shadows across the network.

That single fact matters in different ways:

- the control room wants the latest status
- the alert desk wants a notification
- analytics wants to count the delay

The network should not have to know which of those reactions will occur ahead of time. It should only announce that the shipment is delayed and let the rest of the system decide what that fact means in its own domain.

This is where the bus starts feeling like shared infrastructure rather than a helper function.

## Under The Hood

Fan-out becomes visible here.

In PubSub, one broadcast can wake up any number of subscribers. The producer does not branch manually into dashboard code, alert code, and analytics code. It emits one event, and the topic does the distribution work.

That matters because it keeps the producer stable while the rest of the system evolves.

## Network Changes

The control room stays, and the network adds:

- `SignalNetwork.Consumers.AlertSink`
- `SignalNetwork.Consumers.AnalyticsSink`
- top-level helpers for reading alerts and analytics counters

The producer still only calls `SignalNetwork.announce/1`.

## The Code

The fan-out layer lives in:

- [`lib/consumers/alert_sink.ex`](./lib/consumers/alert_sink.ex)
- [`lib/consumers/analytics_sink.ex`](./lib/consumers/analytics_sink.ex)
- [`lib/signal_network.ex`](./lib/signal_network.ex)

The analytics sink shows the pattern clearly:

```elixir
def handle_info(%Signal{} = signal, state) do
  {:noreply, Map.update(state, signal.event, 1, &(&1 + 1))}
end
```

The sink does not care who emitted the event. It only cares that it arrived.

## Trying It Out

Run the chapter:

```bash
cd 03_many_receivers_one_signal
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()
SignalNetwork.listen("trade:shipment-17")

signal =
  SignalNetwork.announce(%{
    source: :trade_authority,
    topic: "trade:shipment-17",
    event: :shipment_delayed,
    payload: %{status: "delayed", reason: "solar winds", minutes: 42}
  })

receive do
  _message -> :ok
after
  200 -> :timeout
end

%{
  control_room: SignalNetwork.dashboard_snapshot()["trade:shipment-17"],
  alerts: SignalNetwork.alerts(),
  analytics: SignalNetwork.analytics(),
  signal: signal
}
```

## What the Tests Prove

The tests prove that one shipment delay:

- reaches a direct subscriber
- updates the control-room projection
- lands in the alert sink
- increments the analytics counter

No producer branching is required.

## Why This Matters

Fan-out is where PubSub starts to feel architectural instead of merely convenient.

Once many consumers can react independently, you can add new behavior without reopening the producer every time.

## What Holds

A producer should emit one fact once.

If multiple reactions are needed, topics are where that multiplicity belongs.

## What Still Hurts

Operators still do not have a real client surface.

The control room is live inside the server, but there is still no dashboard connection that can join once and receive pushes over time.

## Next Shift

Next, operators join a Phoenix Channel and the control room starts pushing updates over a real-time client connection.
