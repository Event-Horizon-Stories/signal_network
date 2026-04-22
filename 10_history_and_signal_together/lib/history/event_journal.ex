defmodule SignalNetwork.History.EventJournal do
  @moduledoc """
  Stores a durable copy of sequence-tagged signals.
  """

  use GenServer

  alias SignalNetwork.Signals.Signal

  @doc """
  Starts the in-memory journal.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc """
  Appends one signal to the journal.
  """
  @spec append(Signal.t()) :: :ok
  def append(%Signal{} = signal) do
    GenServer.call(__MODULE__, {:append, signal})
  end

  @doc """
  Looks up journaled signals for one source and a set of sequences.
  """
  @spec lookup(atom(), [pos_integer()]) :: [Signal.t()]
  def lookup(source, sequences) do
    GenServer.call(__MODULE__, {:lookup, source, sequences})
  end

  @doc """
  Clears the journal.
  """
  @spec reset() :: :ok
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:append, signal}, _from, state) do
    {:reply, :ok, [signal | state]}
  end

  def handle_call({:lookup, source, sequences}, _from, state) do
    replies =
      state
      |> Enum.filter(&(&1.source == source and &1.sequence in sequences))
      |> Enum.sort_by(& &1.sequence)

    {:reply, replies, state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok, []}
  end
end
