defmodule Sandbox.Consumer do
  use GenStage

  require Logger

  @state []

  def start_link(_) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def status, do: GenStage.call(__MODULE__, :status)

  def init(_) do
    {:consumer, @state, subscribe_to: [{Sandbox.Producer, []}]}
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
