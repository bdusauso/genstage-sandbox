# GenStage Sandbox

**This is a _hobby_ project whose sole purpose is to learn more about how [GenStage](https://github.com/elixir-lang/gen_stage) works.**

## Description of the problem

The goal is to process events, *one at a time* and to provide resilience in case of the crash of the consumer. In order to achieve this, each event is carrying a unique identifier (UUIDv4) and an acknowledgement is sent to the producer at the end of the processing. If the id sent by the consumer matches the one kept in the state of the producer, it is considered as successful and discarded, and the consumer can send the next event. Otherwise, the same message is sent again until an acknowledgement is received.

## Usage

* Open a console: `iex -S mix`
* Send some messages: `for i <- 1..60, do: Sandbox.publish("Message #{i}")`
* Kill the consumer and watch the message being sent again: `Sandbox.Consumer |> Process.whereis() |> Process.exit(:kill)`

**Note**: the processing time of each message is set by default to 1 second.
