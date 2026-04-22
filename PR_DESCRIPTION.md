## Summary

This PR creates `signal_network`, a cumulative Elixir tutorial repo that teaches PubSub through the Interplanetary Signal Network story.

The learning goal is PubSub, but the series teaches it as a system shape rather than a list of APIs:

- signals are emitted by planets, stations, and ships
- dashboards, alerting, and analytics react by listening
- mission-control clients receive updates over Phoenix Channels
- Presence shows who and what is online
- clustered relays show cross-node propagation and failure tolerance
- storm filtering and priority feeds show overload behavior
- partition tracking exposes the limit of PubSub with no persistence
- an event journal completes the picture with recovery and replay

## Chapter Arc

The series contains ten numbered lessons:

1. naive polling failure
2. topics, subscribe, and broadcast
3. fan-out to multiple subscribers
4. real-time channels
5. presence
6. clustered planet relays
7. backpressure under a solar storm
8. priority-aware routing
9. partition gaps and PubSub limits
10. history plus live distribution

Each lesson is its own Mix project, but every lesson is the next version of the same app. Only the chapter folder changes. The internal app stays `:signal_network`, the namespace stays `SignalNetwork`, and the public surface evolves instead of being renamed per chapter.

## Educational Assets

- root README with the full journey and entry points
- one README per lesson with a stable teaching structure
- one Livebook companion per lesson under `livebooks/`
- beginner-friendly `@moduledoc` and `@doc` coverage on the lesson code
- concise GitHub repo description in `GITHUB_DESCRIPTION.md`

## Verification

Verified locally:

- `mix test` in all ten lessons
- Phoenix dependency resolution for the PubSub and channel lessons
- README and livebook examples aligned to the implemented APIs while writing the docs
- shared namespace and OTP app naming consistency across all chapters
- chapter-only folder renaming with stable internal module naming throughout
