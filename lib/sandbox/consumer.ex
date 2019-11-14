defmodule Sandbox.Consumer do
  use GenStage

  require Logger

  @state []

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  def status, do: GenStage.call(__MODULE__, :status)

  def init(opts) do
    producer = Keyword.fetch!(opts, :producer)
    {:consumer, @state, subscribe_to: [{producer, []}]}
  end

  def handle_call(:status, _from, state), do: {:reply, state, [], state}

  def handle_events([{payload, id}], {pid, _}, _) do
    Logger.debug("Processing message ##{id}")

    process_payload(payload)
    ack_message(pid, id)

    {:noreply, [], @state}
  end

  defp ack_message(pid, id) do
    send(pid, {:ack, id})
  end

  defp process_payload(_payload) do
    Process.sleep(1000)
  end
end
