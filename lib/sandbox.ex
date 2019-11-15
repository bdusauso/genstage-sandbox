defmodule Sandbox do
  @moduledoc """
  Documentation for Sandbox.
  """

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts, module: __CALLER__.module] do
      @doc false
      def child_spec(arg) do
        default = %{
          id: unquote(module),
          start: {__MODULE__, :start_link, [arg]}
        }

        Supervisor.child_spec(default, unquote(Macro.escape(opts)))
      end

      @doc """
      Publish a message.

      ## Examples

          iex> Sandbox.publish("Hello World!")
          :ok

      """
      def publish(message), do: GenServer.call(producer_name(), {:publish, {message, UUID.uuid4()}})

      def generate_messages(count \\ 5000) do
        Enum.each(1..count, &publish("Message #{&1}"))
      end

      def consumer_name(), do: :"#{unquote(module)}.Consumer"

      defp producer_name(), do: :"#{unquote(module)}.Producer"

      defoverridable child_spec: 1
    end
  end

  def start_link(module, _opts) do
    children = [
      {Sandbox.Fifo, [name: :"#{module}.Buffer"]},
      {Sandbox.Producer, [name: :"#{module}.Producer", buffer: :"#{module}.Buffer"]},
      {Sandbox.Consumer, [name: :"#{module}.Consumer", producer: :"#{module}.Producer"]}
    ]

    opts = [strategy: :one_for_one, name: :"#{module}.Supervisor"]
    Supervisor.start_link(children, opts)
  end
end
