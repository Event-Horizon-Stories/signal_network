# Livebook Companions

These notebooks are the interactive companions for `signal_network`.

Open them from Livebook while the repository is checked out locally. Each notebook uses a local path dependency back to its lesson directory so the examples stay attached to the real lesson code.

## Setup

From the repo root:

```bash
./scripts/install_livebook.sh
./scripts/livebook.sh server livebooks
```

## Notebooks

- [01_polling_the_void.livemd](./01_polling_the_void.livemd) for the polling failure
- [02_listen_to_the_signal.livemd](./02_listen_to_the_signal.livemd) for first broadcasts and subscriptions
- [03_many_receivers_one_signal.livemd](./03_many_receivers_one_signal.livemd) for PubSub fan-out
- [04_channels_under_glass.livemd](./04_channels_under_glass.livemd) for channel pushes
- [05_presence_in_mission_control.livemd](./05_presence_in_mission_control.livemd) for mission-control presence
- [06_planets_on_separate_nodes.livemd](./06_planets_on_separate_nodes.livemd) for clustered relays
- [07_solar_storm_backpressure.livemd](./07_solar_storm_backpressure.livemd) for storm filtering
- [08_priority_on_the_wire.livemd](./08_priority_on_the_wire.livemd) for priority feeds
- [09_when_a_planet_goes_dark.livemd](./09_when_a_planet_goes_dark.livemd) for delivery gaps
- [10_history_and_signal_together.livemd](./10_history_and_signal_together.livemd) for replay from the journal

## Opening The Series

Start with `01_polling_the_void.livemd`, then move in order. Each notebook assumes the previous lesson's mental model still matters.
