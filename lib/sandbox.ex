defmodule Sandbox do
  @moduledoc """
  Documentation for Sandbox.
  """

  @doc """
  Publish a message.

  ## Examples

      iex> Sandbox.publish("Hello World!")
      :ok

  """
  def publish(message), do: GenServer.cast(Sandbox.Producer, {:publish, {message, UUID.uuid4()}})

  def generate_messages(count \\ 5000) do
    Enum.each(1..count, &publish("Message #{&1}"))
  end
end
