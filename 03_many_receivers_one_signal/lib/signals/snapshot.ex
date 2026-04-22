defmodule SignalNetwork.Signals.Snapshot do
  @moduledoc """
  A polled dashboard view.

  Snapshots are deliberately inert. Once captured, they never change. That is
  useful for showing how polling falls behind the world it is trying to observe.
  """

  @enforce_keys [:dashboard_id, :captured_at_tick, :latest_by_topic, :remote_reads]
  defstruct [:dashboard_id, :captured_at_tick, :latest_by_topic, :remote_reads]

  @type t :: %__MODULE__{
          dashboard_id: String.t(),
          captured_at_tick: non_neg_integer(),
          latest_by_topic: %{optional(String.t()) => SignalNetwork.Signals.Signal.t()},
          remote_reads: pos_integer()
        }
end
