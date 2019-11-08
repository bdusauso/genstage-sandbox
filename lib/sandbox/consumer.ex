defmodule Sandbox.Consumer do
  use GenStage

  require Logger

  alias __MODULE__, as: State

  defstruct last_id: nil

  def start_link(_) do
    GenStage.start_link(__MODULE__, [], name: Consumer)
  end

  def init(_) do
    {:consumer, %State{}, subscribe_to: [{Producer, [max_demand: 1, min_demand: 0]}]}
  end

  def handle_events([{_, id}], _from, %State{last_id: nil} = state) do
    # Since last_id can be nil either at startup or after a crash,
    # we accept all values and proceed as if it was normal
    ack_message(id)
    {:noreply, [], %State{state | last_id: id}}
  end

  def handle_events([{_, id}], _from, state) do
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
    send(Producer, {:ack, id})
  end
end
