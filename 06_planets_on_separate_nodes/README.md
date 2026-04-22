# Lesson 06: Planets On Separate Nodes

Now the network starts to feel wide.

Until this point, the signal network has still felt close enough to imagine as one operational space. That illusion breaks once different worlds begin speaking with their own local rhythm. Mars should be able to keep speaking even if Deimos stumbles. Deimos should still matter even if Mars goes dark. That is the moment when one shared bus stops being enough as a teaching model.

Interactive companion: [`../livebooks/06_planets_on_separate_nodes.livemd`](../livebooks/06_planets_on_separate_nodes.livemd)

## What You'll Learn

- how to model planet-local emission before relaying into a shared network bus
- how clustered propagation differs from a single-node mental model
- how to think about node failure as a topology problem
- how later projections and channels can stay unchanged above the relay layer

## The Story

Signals no longer feel like they all originate from the same room, because they do not. Mars has its own local machinery, its own failures, its own timing. Deimos has another. Their messages still need to reach mission control, but they should arrive there as travelers, not as artifacts of one collapsed simulation.

Mars emits from its own local bus. Deimos emits from another. The control room still wants one live picture, but it should not need a direct line into every device on every world.

So each planet gets a relay. The network grows a backbone instead of a shortcut.

## The PubSub Concept

This chapter teaches clustered propagation in a form you can inspect directly inside one lesson.

Each planet has:

- a local PubSub bus
- a relay process subscribed to that local bus
- a bridge into the shared network bus used by the rest of the app

The consumers above that layer do not care where the signal originated. They only care that it made it onto the shared fabric.

## What We're Building

This lesson keeps chapters 1 through 5 intact and adds:

- two planet-local PubSub servers
- `SignalNetwork.PlanetRelay`
- `SignalNetwork.announce_from_planet/2`
- a failure simulation through `SignalNetwork.stop_planet/1`

## The Code

The clustering layer lives in:

- [`lib/signal_network_planet_relay.ex`](./lib/signal_network_planet_relay.ex)
- [`lib/signal_network/application.ex`](./lib/signal_network/application.ex)
- [`lib/signal_network.ex`](./lib/signal_network.ex)

The relay only needs to bridge one message shape:

```elixir
def handle_info({:planet_signal, %Signal{} = signal}, state) do
  :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), signal.topic, signal)
  :ok = PubSub.broadcast(SignalNetwork.pubsub_name(), SignalNetwork.control_room_topic(), signal)
  {:noreply, state}
end
```

The shared network stays consistent even though signals begin locally.

## Trying It Out

Run the lesson:

```bash
cd 06_planets_on_separate_nodes
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()

SignalNetwork.announce_from_planet(:mars, %{
  source: :mars_colony,
  topic: "telemetry:mars",
  event: :energy_level,
  payload: %{percent: 68}
})

Process.sleep(20)

SignalNetwork.dashboard_snapshot()["telemetry:mars"]
```

The tests also stop one relay and confirm that another planet can still feed the control room.

## What the Tests Prove

The tests prove that:

- a planet-local signal reaches the shared control room
- stopping one relay does not silence the other planet
- earlier polling behavior still remains intact

The cluster layer is additive, not a rewrite.

## Why This Matters

Distribution changes how you think about failure.

The question is no longer only whether a function works. The question becomes whether a region of the network can fail without collapsing the rest of the signal path.

## PubSub Takeaway

Clustering is PubSub plus topology.

Once messages can originate in different places, relays and failure boundaries become part of the design.

## What Still Hurts

A wide network can still drown itself.

If a solar storm sprays low-value chatter across every bus, the control room will still try to swallow it all.

## Next Lesson

In lesson 7, a storm gate starts shedding low-priority traffic so the shared bus can survive overload.
