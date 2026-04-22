defmodule SignalNetwork.Web.ChannelBridge do
  @moduledoc """
  Pushes live bus events onto the operator channel topic.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SignalNetwork.Signals.Signal

  @doc """
  Starts the channel bridge.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  @impl true
  def init(state) do
    :ok = PubSub.subscribe(SignalNetwork.pubsub_name(), SignalNetwork.control_room_topic())
    {:ok, state}
  end

  @impl true
  def handle_info(%Signal{} = signal, state) do
    SignalNetwork.Web.Endpoint.broadcast!(SignalNetwork.channel_topic(), "signal", %{
      topic: signal.topic,
      event: signal.event,
      payload: signal.payload,
      priority: signal.priority
    })

    {:noreply, state}
  end
end
