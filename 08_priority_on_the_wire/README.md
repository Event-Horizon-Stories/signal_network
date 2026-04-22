# Lesson 08: Priority On The Wire

Not every signal deserves the same path.

A shipment delay matters. A reactor failure matters more. Once the storm gate exists, the next honest step is to encode that difference into the topic design itself.

Interactive companion: [`../livebooks/08_priority_on_the_wire.livemd`](../livebooks/08_priority_on_the_wire.livemd)

## What You'll Learn

- how to route one signal onto both a domain topic and a priority feed
- how priority topics give consumers a faster, narrower subscription surface
- why topic naming is a design tool, not just a string convention
- how to preserve earlier overload and clustering behavior while sharpening urgency

## The Story

Mission control can survive a storm now, but it still has to listen widely to know when something catastrophic is happening.

That is too blunt.

Critical failures should have a clean line through the network. Lower-value events can still move, but they should not hide the fire.

## The PubSub Concept

Topic design is part of the model.

In this chapter, `SignalNetwork.PriorityRouter` sends every surviving signal to:

- its domain topic, such as `"trade:shipment-17"`
- a priority topic, such as `"priority:high"`

That lets a consumer subscribe by business area, by urgency, or by both.

## What We're Building

This lesson keeps the storm gate and adds:

- `SignalNetwork.PriorityRouter`
- `SignalNetwork.priority_topic/1`
- `SignalNetwork.listen_priority/1`

The router becomes the one place that decides how urgency appears on the wire.

## The Code

The priority routing path lives in:

- [`lib/signal_network_priority_router.ex`](./lib/signal_network_priority_router.ex)
- [`lib/signal_network_storm_gate.ex`](./lib/signal_network_storm_gate.ex)
- [`lib/signal_network.ex`](./lib/signal_network.ex)

The router is intentionally simple:

```elixir
def dispatch(%Signal{} = signal) do
  :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), signal.topic, signal)
  :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), SignalNetwork.priority_topic(signal.priority), signal)
  :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), SignalNetwork.control_room_topic(), signal)
end
```

One signal, three audiences.

## Trying It Out

Run the lesson:

```bash
cd 08_priority_on_the_wire
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()
SignalNetwork.listen_priority(:high)
SignalNetwork.listen_priority(:low)

SignalNetwork.announce(%{
  source: :trade_authority,
  topic: "trade:shipment-17",
  event: :shipment_delayed,
  payload: %{status: "delayed"},
  priority: :low
})

SignalNetwork.announce(%{
  source: :mars_colony,
  topic: "alerts:mars",
  event: :reactor_failure,
  payload: %{sector: "ring-2"},
  priority: :high
})

messages =
  for _ <- 1..2 do
    receive do
      message -> message
    after
      200 -> :timeout
    end
  end

Enum.map(messages, &{&1.event, &1.priority})
```

## What the Tests Prove

The tests prove that:

- earlier polling still behaves the same way
- low-priority and high-priority signals land on their respective feeds
- the control room still receives the domain-level update

Urgency is now explicit on the wire instead of implicit in the payload.

## Why This Matters

PubSub topics are more than routing keys. They are part of how the system thinks.

A good topic scheme makes the important subscriptions obvious before you write the consumers.

## PubSub Takeaway

Topic design is policy made visible.

If events have different operational weight, the bus should say so.

## What Still Hurts

Even a well-routed live network can still forget.

If a planet disappears from the wire and returns later, PubSub alone has no memory of the signals that never arrived.

## Next Lesson

In lesson 9, a reconnect reveals missing sequence gaps and makes PubSub’s lack of persistence impossible to ignore.
