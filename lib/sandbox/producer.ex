defmodule Sandbox.Producer do
  use GenStage

  require Logger

  import Sandbox.Fifo, except: [start_link: 1]

  defmodule State do
    defstruct buffer: nil,
              to_ack: nil,
              consumer: nil
  end

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, [])
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    buffer = Keyword.fetch!(opts, :buffer)

    Process.flag(:trap_exit, true)
    Process.register(self(), name)

    {:producer, %State{buffer: buffer}}
  end

  def handle_cast({:publish, {_, id} = message}, %State{consumer: nil} = state) do
    Logger.debug("Publish message ##{id}")

    enqueue(state.buffer, message)
    to_ack = if state.to_ack, do: state.to_ack, else: peek(state.buffer)

    {:noreply, [], %State{state | to_ack: to_ack}}
  end

  def handle_cast({:publish, {_, id} = message}, %State{} = state) do
    Logger.debug("Publish message ##{id}")

    enqueue(state.buffer, message)
    {events, to_ack} =
      case state.to_ack do
        nil ->
          elem = peek(state.buffer)
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
      if empty?(state.buffer),
        do: {[], nil},
        else: {[peek(state.buffer), peek(state.buffer)]}

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
    Logger.debug("Received ack for message ##{id}")
    dequeue(state.buffer)
    {events, to_ack} =
      if empty?(state.buffer),
        do: {[], nil},
        else: {[peek(state.buffer)], peek(state.buffer)}

    {:noreply, events, %State{state | to_ack: to_ack}}
  end

  def handle_subscribe(:consumer, _options, {pid, _}, %State{} = state) do
    Logger.debug("Received subscription from #{inspect(pid)}")
    Process.monitor(pid)
    {:automatic, %State{state | consumer: pid}}
  end
end
