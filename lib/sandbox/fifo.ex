defmodule Sandbox.Fifo do
  use Agent

  @name __MODULE__

  def start_link(opts) do
    Agent.start_link(fn -> :queue.new() end, opts)
  end

  def size(client \\ @name), do: Agent.get(client, &:queue.len/1)

  def empty?(client \\ @name), do: Agent.get(client, &:queue.is_empty/1)

  def enqueue(client \\ @name, elem) do
    Agent.update(client, &:queue.in(elem, &1))
  end

  def dequeue(client \\ @name) do
    Agent.get_and_update(client, fn q ->
      case :queue.out(q) do
        {{:value, v}, queue} ->
          {v, queue}

        {:empty, _} ->
          {nil, q}
      end
    end)
  end

  def peek(client \\ @name) do
    Agent.get(client, fn q ->
      case :queue.peek(q) do
        {:value, v} ->
          v

        :empty ->
          nil
      end
    end)
  end
end
