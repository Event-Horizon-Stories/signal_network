defmodule SignalNetwork.Signal do
  @moduledoc """
  A single announcement traveling through the network.

  Later lessons will broadcast these signals over Phoenix PubSub, but the shape
  stays the same from the first lesson onward.
  """

  @enforce_keys [:tick, :source, :topic, :event, :payload]
  defstruct [:tick, :source, :topic, :event, :payload, priority: :normal]

  @type priority :: :high | :normal | :low

  @type t :: %__MODULE__{
          tick: pos_integer(),
          source: atom(),
          topic: String.t(),
          event: atom(),
          payload: map(),
          priority: priority()
        }

  @doc """
  Builds a signal and normalizes its priority.
  """
  @spec new!(map()) :: t()
  def new!(attrs) do
    struct!(__MODULE__, Map.update(attrs, :priority, :normal, &normalize_priority!/1))
  end

  defp normalize_priority!(priority) when priority in [:high, :normal, :low], do: priority

  defp normalize_priority!(priority) do
    raise ArgumentError, "unsupported signal priority: #{inspect(priority)}"
  end
end
