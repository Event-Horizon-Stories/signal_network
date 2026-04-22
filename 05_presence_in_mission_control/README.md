# Lesson 05: Presence In Mission Control

The dashboard is live now, but a live dashboard is not the same thing as a coordinated room.

A real control surface is not only made of events. It is also made of occupants, absences, handoffs, and the uneasy silence that falls when a system that should be online stops speaking. Once signals are fast enough, presence itself becomes operational data.

Mission control needs to know which operators are online, and which systems are still speaking clearly enough to trust.

Interactive companion: [`../livebooks/05_presence_in_mission_control.livemd`](../livebooks/05_presence_in_mission_control.livemd)

## What You'll Learn

- how to add Phoenix Presence to a PubSub-backed channel
- how to track both human operators and connected systems
- how to list presence state from inside the app
- why presence belongs beside live updates in operational software

## The Story

Signals are arriving fast enough now that silence itself becomes information.

If a reactor monitor drops off the wire, that matters before anyone reads the next metric. If the night-shift operator leaves mission control and no one else is present to take the room, that matters too. In a living network, absence has shape. Presence gives that shape a place to be recorded.

This chapter turns the room itself into part of the system model.

## The PubSub Concept

Presence is built on PubSub, but it solves a different problem from ordinary event fan-out.

PubSub says:

- a message arrived

Presence says:

- this actor is here
- this actor is gone
- this room currently contains these participants

That distinction matters. Presence is not one more event type. It is shared membership state maintained over the same messaging fabric.

## What We're Building

This lesson keeps the channel from chapter 4 and adds:

- `SignalNetwork.Presence`
- operator tracking on channel join
- system tracking through `SignalNetwork.track_system/2`
- helper functions for `operators_online/0` and `systems_online/0`

## The Code

The presence layer lives in:

- [`lib/signal_network_presence.ex`](./lib/signal_network_presence.ex)
- [`lib/signal_network_operator_channel.ex`](./lib/signal_network_operator_channel.ex)
- [`lib/signal_network.ex`](./lib/signal_network.ex)

The important move happens after join:

```elixir
{:ok, _meta} =
  SignalNetwork.Presence.track(
    self(),
    socket.topic,
    socket.assigns.operator,
    %{role: "operator", joined_via: "channel"}
  )
```

The channel becomes both a live event stream and a place with occupants.

## Trying It Out

Run the lesson:

```bash
cd 05_presence_in_mission_control
mix deps.get
mix test
iex -S mix
```

Then paste:

```elixir
SignalNetwork.reset_runtime!()

SignalNetwork.track_system("mars-colony-core", %{kind: "life-support", online: true})

%{
  systems: SignalNetwork.systems_online(),
  operators: SignalNetwork.operators_online()
}
```

To watch operator presence itself, the test suite is the clearest path because it joins the channel and asserts the pushed `"presence_state"` payload.

## What the Tests Prove

The tests prove that:

- polling still behaves the way earlier chapters taught it to
- a connected system is visible in Presence
- an operator joining the channel becomes visible in Presence

Mission control can now see not only the signal, but the room that is responding to it.

## Why This Matters

Operational software is not just about data freshness. It is also about coordination.

Knowing who is online, and whether the right systems are still connected, changes how humans interpret the same stream of events.

## PubSub Takeaway

Presence is membership state built on top of PubSub.

The wire can tell you both what happened and who is still around to see it.

## What Still Hurts

Everything still lives on one shared bus.

The story says signals come from many worlds, but the code has not made that distribution pressure visible yet.

## Next Lesson

In lesson 6, planets get their own local buses and relay into the wider network so node-level failure becomes part of the story.
