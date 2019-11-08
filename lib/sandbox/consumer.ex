defmodule Sandbox.Consumer do
  use GenStage

  require Logger

  alias __MODULE__, as: State

  defstruct last_id: nil

  def start_link(_) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:consumer, %State{}, subscribe_to: [{Sandbox.Producer, [min_demand: 0, max_demand: 1]}]}
  end

  def handle_events([{_, id}], _from, %State{last_id: nil} = state) do
    Logger.info("Processing message ##{id}")
    # Since last_id can be nil either at startup or after a crash,
    # we accept all values and proceed as if it was normal
    ack_message(id)
    {:noreply, [], %State{state | last_id: id}}
  end

  def handle_events([{_, id}], _from, state) do
    Logger.info("Processing message ##{id}")
    if id == state.last_id + 1 do
      # Ok, we have the events in strict order
      ack_message(id)
      {:noreply, [], %State{state | last_id: id}}
    else
      # We miss a message
      {:stop, :missing_message, state}
    end
  end

  defp ack_message(id) do
    send(Sandbox.Producer, {:ack, id})
  end
end
