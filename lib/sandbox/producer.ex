defmodule Sandbox.Producer do
  use GenStage

  require Logger

  import Sandbox.Fifo, except: [start_link: 1]

  @buffer Sandbox.Buffer

  defmodule State do
    defstruct to_ack: nil,
              consumer: nil
  end

  def start_link(_) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    {:producer, %State{}}
  end

  def handle_cast({:publish, message}, %State{consumer: nil} = state) do
    Logger.debug("Publish message - #{inspect(state)}")
    enqueue(@buffer, message)
    to_ack = if state.to_ack, do: state.to_ack, else: peek(@buffer)

    {:noreply, [], %State{state | to_ack: to_ack}}
  end

  def handle_cast({:publish, message}, %State{} = state) do
    Logger.debug("Publish message - #{inspect(state)}")
    enqueue(@buffer, message)
    {events, to_ack} =
      case state.to_ack do
        nil ->
          elem = peek(@buffer)
          {[elem], elem}

        _ ->
          {[], state.to_ack}
      end

    {:noreply, events, %State{state | to_ack: to_ack}}
  end

  def handle_demand(_, %State{consumer: nil} = state) do
    Logger.debug("Received demand - #{inspect(state)}")
    # Can we get here ?
    {:noreply, [], state}
  end

  def handle_demand(_, %State{to_ack: nil} = state) do
    Logger.debug("Received demand - #{inspect(state)}")
    {events, to_ack} =
      if empty?(@buffer),
        do: {[], nil},
        else: {[peek(@buffer), peek(@buffer)]}

    {:noreply, events, %State{state | to_ack: to_ack}}
  end

  def handle_demand(_, %State{} = state) do
    Logger.debug("Received demand - #{inspect(state)}")
    {:noreply, [state.to_ack], state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{consumer: pid} = state) do
    Logger.debug("Consumer down, cleaning state")
    {:noreply, [], %State{state | consumer: nil}}
  end

  def handle_info({:ack, id}, %State{to_ack: {_, id}} = state) do
    Logger.debug("Received ack #{id}")
    dequeue(@buffer)
    {events, to_ack} =
      if empty?(@buffer),
        do: {[], nil},
        else: {[peek(@buffer)], peek(@buffer)}

    {:noreply, events, %State{state | to_ack: to_ack}}
  end

  def handle_subscribe(:consumer, _options, {pid, _}, %State{} = state) do
    Logger.debug("Received subscription from #{inspect(pid)}")
    Process.monitor(pid)
    {:automatic, %State{state | consumer: pid}}
  end
end
