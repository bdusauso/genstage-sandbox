defmodule Sandbox.Producer do
  use GenStage

  require Logger

  alias __MODULE__, as: State

  defstruct buffer: [],
            counter: 0

  def start_link(_) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:producer, %State{}}
  end

  def handle_cast({:publish, payload}, %State{} = state) do
    message = {payload, state.counter}
    {:noreply, [message], %State{buffer: List.insert_at(state.buffer, -1, message)}}
  end

  def handle_demand(_, %State{buffer: []} = state), do: {:noreply, [], state}

  def handle_demand(_, state) do
    {:noreply, [List.first(state.buffer)], state}
  end

  def handle_info({:ack, id}, state) do
    message = {_, expected_id} = List.first(state.buffer)

    # If the acked id we just got is the one we expected,
    # then we publish the next message from the buffer.
    # Otherwise we send the last message again (???)
    if id == expected_id do
      new_buffer = Enum.drop(state.buffer, 1)
      next_event = if Enum.empty?(new_buffer), do: [], else: [List.first(new_buffer)]
      {:noreply, next_event, %State{state | buffer: new_buffer, counter: state.counter + 1}}
    else
      {:noreply, [message], state}
    end
  end
end
