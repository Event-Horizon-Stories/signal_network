# signal_network

`signal_network` teaches PubSub by following a network that feels alive before it feels abstract.

Across Mars habitats, drifting ships, trade relays, and mission-control consoles, nothing sits still long enough to be politely requested. Oxygen levels dip. Reactors grow unstable. Shipments stall in radiation and wind. Operators sign on, vanish, and hand the room to someone else. The system does not pause so a dashboard can catch up. It keeps speaking.

That is the mental shift this series is built around. PubSub is not introduced here as a messaging primitive in isolation. It is introduced as the natural shape of a world where state moves through announcements, reactions, and live coordination. Every lesson takes the same `SignalNetwork` application one step further into that reality.

## Interactive Companions

Livebook companions for the full series live in [`livebooks/`](./livebooks/README.md).

- [`livebooks/01_polling_the_void.livemd`](./livebooks/01_polling_the_void.livemd)
- [`livebooks/02_listen_to_the_signal.livemd`](./livebooks/02_listen_to_the_signal.livemd)
- [`livebooks/03_many_receivers_one_signal.livemd`](./livebooks/03_many_receivers_one_signal.livemd)
- [`livebooks/04_channels_under_glass.livemd`](./livebooks/04_channels_under_glass.livemd)
- [`livebooks/05_presence_in_mission_control.livemd`](./livebooks/05_presence_in_mission_control.livemd)
- [`livebooks/06_planets_on_separate_nodes.livemd`](./livebooks/06_planets_on_separate_nodes.livemd)
- [`livebooks/07_solar_storm_backpressure.livemd`](./livebooks/07_solar_storm_backpressure.livemd)
- [`livebooks/08_priority_on_the_wire.livemd`](./livebooks/08_priority_on_the_wire.livemd)
- [`livebooks/09_when_a_planet_goes_dark.livemd`](./livebooks/09_when_a_planet_goes_dark.livemd)
- [`livebooks/10_history_and_signal_together.livemd`](./livebooks/10_history_and_signal_together.livemd)

## The Journey

Each lesson is its own standalone Mix project, but every chapter is the next version of the same app carried forward under the same `SignalNetwork` namespace and `:signal_network` OTP app:

1. [`01_polling_the_void`](./01_polling_the_void/README.md)
   Mission control polls the universe and immediately feels the cost of stale snapshots and repeated reads.
2. [`02_listen_to_the_signal`](./02_listen_to_the_signal/README.md)
   The network starts broadcasting over Phoenix PubSub, and the control room begins updating by subscription instead of request.
3. [`03_many_receivers_one_signal`](./03_many_receivers_one_signal/README.md)
   One delayed shipment fans out into dashboard updates, operator alerts, and analytics counters.
4. [`04_channels_under_glass`](./04_channels_under_glass/README.md)
   Operator dashboards join a Phoenix Channel and receive live pushes without refreshes.
5. [`05_presence_in_mission_control`](./05_presence_in_mission_control/README.md)
   Mission control learns who is online and which systems are still connected with Phoenix Presence.
6. [`06_planets_on_separate_nodes`](./06_planets_on_separate_nodes/README.md)
   Planet-local buses relay into the shared network so one outage does not silence the rest.
7. [`07_solar_storm_backpressure`](./07_solar_storm_backpressure/README.md)
   A storm gate sheds low-priority chatter before the shared bus chokes.
8. [`08_priority_on_the_wire`](./08_priority_on_the_wire/README.md)
   The same signal now travels on both domain topics and priority feeds, giving critical failures a faster path.
9. [`09_when_a_planet_goes_dark`](./09_when_a_planet_goes_dark/README.md)
   A reconnect can prove that signals were missed, but PubSub alone cannot replay the lost history.
10. [`10_history_and_signal_together`](./10_history_and_signal_together/README.md)
    A journaled event path joins the live bus so the network gains both instant propagation and recoverable history.

## Final Inquiry Shape

By the end of the series, the network has a clear layered shape:

```text
signal source
  -> planet-local emission
  -> storm gate
  -> priority-aware PubSub topics
  -> control-room projection
  -> channels and presence for operators
  -> event journal for replay and recovery
```

That is the full inquiry shape of the series: live reaction in the foreground, durable history behind it, and a hard boundary between the two.

## Beyond the Series

The ten main chapters cover the PubSub arc most readers need:

- polling versus listening
- topics, broadcasts, and subscriptions
- fan-out
- channels
- presence
- clustered relays
- backpressure
- priority routing
- delivery gaps
- event journal integration

There are stronger follow-up paths if you want to keep going:

- a real multi-node BEAM cluster instead of simulated planet-local buses
- persistent subscriptions backed by Broadway, Oban, or external brokers
- richer channel clients with LiveView or a browser dashboard
- external event stores and replayable projections

## Tooling

The repo is pinned with `.tool-versions` so the lessons run against an asdf-managed Elixir and Erlang toolchain.

Each lesson is its own Mix project. Fetch dependencies inside the lesson you want to run:

```bash
cd 04_channels_under_glass
mix deps.get
mix test
```

For the Livebook companions, use the repo-root helper scripts:

```bash
./scripts/install_livebook.sh
./scripts/livebook.sh server livebooks
```

## Start Here

Begin with [`01_polling_the_void`](./01_polling_the_void/README.md).

That lesson teaches the first hard truth of the series: if dashboards keep asking for the latest state, they are already late.
