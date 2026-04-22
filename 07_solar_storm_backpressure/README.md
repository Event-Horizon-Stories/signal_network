# Lesson 07: Solar Storm Backpressure

The network is alive enough to be in danger now.

A quiet system can afford naive honesty. It can pass along every small fact and trust that nothing important will be buried. A living system under pressure loses that luxury. Once the wire starts filling with noise, survival depends on deciding what deserves space.

When a solar storm starts spraying low-value chatter across the wire, the control room needs a way to keep breathing without pretending every signal deserves the same path.

Interactive companion: [`../livebooks/07_solar_storm_backpressure.livemd`](../livebooks/07_solar_storm_backpressure.livemd)

## What You'll Learn

- how to add a gate in front of PubSub dispatch
- how to drop low-priority traffic under burst pressure
- why overload handling belongs at the boundary, not inside every consumer
- how to preserve urgent signals while trimming noise

## The Story

The storm is not subtle. It arrives as a flood of technically accurate, operationally distracting speech. Ships start pinging constantly. Trade updates repeat. Small state changes ripple faster than anyone can interpret them. The bus begins to fill with messages that are true, but not equally worth hearing.

Meanwhile, the signal that matters most is the one the network must not lose: a reactor drifting toward failure.

This chapter introduces pressure into the system on purpose so the filtering policy has something real to protect against.

## The PubSub Concept

PubSub is excellent at propagation. It is not automatically a backpressure strategy.

If you let every signal through without a policy, bursts can starve the traffic you actually care about. This chapter puts a `SignalNetwork.Network.StormGate` in front of the shared bus so the system can make one explicit choice:

- low-priority chatter may be dropped
- urgent traffic must still pass

That is not a replacement for durable queueing, but it is the first honest overload policy in the series.

## What We're Building

This lesson keeps the clustered relays from chapter 6 and adds:

- `SignalNetwork.Network.StormGate`
- `SignalNetwork.dropped_signals/0`
- routing of both direct and planet-relayed signals through the gate

## The Code

The overload policy lives in:

- [`lib/network/storm_gate.ex`](./lib/network/storm_gate.ex)
- [`lib/signal_network.ex`](./lib/signal_network.ex)
- [`lib/network/planet_relay.ex`](./lib/network/planet_relay.ex)

The key branch is the drop decision:

```elixir
if signal.priority == :low and length(recent) >= @max_low_priority do
  {:reply, :ok, %{state | recent: recent, dropped: [signal | state.dropped]}}
else
  :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), signal.topic, signal)
  :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), SignalNetwork.control_room_topic(), signal)
  {:reply, :ok, %{state | recent: [now | recent]}}
end
```

The storm gate does not rewrite the signal. It decides whether the shared bus will see it at all.

## Trying It Out

Run the lesson:

```bash
cd 07_solar_storm_backpressure
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()

for minute <- 1..5 do
  SignalNetwork.announce(%{
    source: :orbital_ship_7,
    topic: "trade:shipment-17",
    event: :shipment_ping,
    payload: %{minute: minute},
    priority: :low
  })
end

SignalNetwork.announce(%{
  source: :mars_colony,
  topic: "alerts:mars",
  event: :reactor_unstable,
  payload: %{variance: 19},
  priority: :high
})

%{
  dropped: SignalNetwork.dropped_signals(),
  live_alert: SignalNetwork.dashboard_snapshot()["alerts:mars"]
}
```

## What the Tests Prove

The tests prove that:

- earlier polling still behaves the same way
- low-priority bursts get dropped under pressure
- a high-priority alert still reaches the control room

That is the first time the system explicitly chooses to lose some traffic so more important traffic can survive.

## Why This Matters

A living network is not only about propagation. It is about restraint.

If you never decide what can be lost, overload will make the decision for you.

## PubSub Takeaway

PubSub needs an overload policy around it.

Backpressure is not the opposite of real time. It is how real time stays believable when the wire gets loud.

## What Still Hurts

The gate can protect the bus, but it still treats most traffic of the same priority as equivalent.

The network needs a clearer language for urgency.

## Next Lesson

In lesson 8, signals start traveling on priority feeds as well as domain topics so urgent failures can cut through the network faster.
