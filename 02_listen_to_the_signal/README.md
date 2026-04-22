# Lesson 02: Listen To The Signal

The network changes shape here.

Up to this point, mission control has been acting like the universe owes it a reply on demand. That posture does not survive contact with a living system for very long. When the reactor starts drifting, Mars should not have to wait for a dashboard refresh to become real. The signal should leave immediately, carrying the fact of the change with it.

That is the first moment when the network starts to feel alive instead of observed from a distance.

Interactive companion: [`../livebooks/02_listen_to_the_signal.livemd`](../livebooks/02_listen_to_the_signal.livemd)

## What You'll Learn

- how to start a Phoenix PubSub bus inside an Elixir application
- how to subscribe a process to a topic with `Phoenix.PubSub.subscribe/2`
- how to broadcast a signal and let the control room update itself
- how polling and PubSub can coexist while you shift the system shape

## The Story

Mission control is still carrying the old polling dashboard from lesson 1, and you can already feel the strain in it. Every request asks the same scattered world to hold still long enough to be summarized. Every answer arrives with a little dust already on it.

So the network changes tactics.

Mars starts announcing alerts the moment they matter. The trade authority starts announcing shipment events as they occur instead of waiting to be queried. The control room stops rereading every source and begins listening for traffic already crossing the wire.

This is the chapter where the system stops asking for permission to notice.

## The PubSub Concept

This chapter introduces the two core PubSub operations:

- subscribe to a topic
- broadcast a message to that topic

The producer does not know who is listening. The consumer does not know who sent the event. They only agree on topic names and message shape.

In this lesson, `SignalNetwork.announce/1` broadcasts a `%SignalNetwork.Signals.Signal{}` to both its domain topic and a shared `"signals:all"` topic. The control room subscribes once and keeps an always-live projection.

## What We're Building

This lesson adds:

- a real `Phoenix.PubSub` server
- a `SignalNetwork.Consumers.ControlRoom` GenServer that subscribes to every signal
- `SignalNetwork.listen/1` for consumers
- `SignalNetwork.announce/1` for producers

The lesson keeps the polling code from chapter 1 intact so you can compare the old and new shapes directly.

## The Code

The new runtime layer lives in:

- [`lib/signal_network.ex`](./lib/signal_network.ex)
- [`lib/runtime/application.ex`](./lib/runtime/application.ex)
- [`lib/consumers/control_room.ex`](./lib/consumers/control_room.ex)

The broadcast path is the new center of gravity:

```elixir
def announce(attrs) do
  signal = runtime_signal(attrs)

  :ok = PubSub.broadcast(pubsub_name(), signal.topic, signal)
  :ok = PubSub.broadcast(pubsub_name(), control_room_topic(), signal)

  signal
end
```

That double broadcast lets consumers choose between a narrow domain topic and a whole-network feed.

## Trying It Out

Run the lesson:

```bash
cd 02_listen_to_the_signal
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()
SignalNetwork.listen("alerts:mars")

signal =
  SignalNetwork.announce(%{
    source: :mars_colony,
    topic: "alerts:mars",
    event: :reactor_unstable,
    payload: %{sector: "reactor-ring", variance: 12},
    priority: :high
  })

received =
  receive do
    message -> message
  after
    200 -> :timeout
  end

%{
  sent: signal.event,
  received: received.event,
  live_control_room: SignalNetwork.dashboard_snapshot()["alerts:mars"].event
}
```

## What the Tests Prove

The tests prove that:

- the old polling snapshot still goes stale
- a subscriber receives a live signal without asking for it
- the control room projection updates itself from PubSub traffic

That is the first real inversion of the series: the dashboard is no longer the one doing the work.

## Why This Matters

PubSub changes the timing of the system.

Instead of a client choosing when the world should be observed, the world decides when it has something worth saying.

That is a more natural fit for alerts, telemetry, shipment updates, and presence events.

## PubSub Takeaway

Topics let producers announce facts without caring who is listening.

That decoupling is the core move. Everything else in the series builds on it.

## What Still Hurts

One subscriber is not a system.

Mission control can hear the signal now, but we still have only one reaction path and one live projection.

## Next Lesson

In lesson 3, one delayed shipment will trigger multiple subscribers at once so fan-out becomes visible instead of abstract.
