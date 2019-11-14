defmodule Sandbox.Producer do
  use GenStage

  require Logger

  import Sandbox.Fifo, except: [start_link: 1]

  @buffer Sandbox.Buffer

  def start_link(_) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:producer, 0}
  end

  def handle_cast({:publish, message}, 0) do
    enqueue(@buffer, message)
    {:noreply, [], 0}
  end

  def handle_cast({:publish, message}, demand) do
    enqueue(@buffer, message)
    event = dequeue(@buffer)
    {:noreply, [event], demand - 1}
  end

  def handle_demand(_, demand_left) do
    {events, demand_left} =
      if empty?(@buffer),
        do: {[], demand_left + 1},
        else: {[dequeue(@buffer)], demand_left}

    {:noreply, events, demand_left}
  end

  def handle_info({:ack, id}, demand_left) do
    # Do nothing for now
    Logger.debug("Received ack #{id}")

    cond do
      match?({_, ^id}, peek(@buffer)) && demand_left > 0 ->
        dequeue(@buffer)
        {events, demand_left} =
          if empty?(@buffer),
            do: {[], demand_left},
            else: {peek(@buffer), demand_left - 1}
        {:noreply, events, demand_left}

      match?({_, ^id}, peek(@buffer)) && demand_left == 0 ->
        dequeue(@buffer)
        {:noreply, [], demand_left}

      demand_left > 0 ->
        {:noreply, [peek(@buffer)], demand_left - 1}

      true ->
        {:noreply, [], demand_left}
    end
  end
end
