# GenStage Sandbox

**This is a _hobby_ project whose sole purpose is to learn more about how [GenStage](https://github.com/elixir-lang/gen_stage) works.**

## Description of the problem

The goal is to process events, *one at a time* and to provide resilience in case of the crash of the consumer. In order to achieve this, each event is carrying a unique identifier (UUIDv4) and an acknowledgement is sent to the producer at the end of the processing. If the id sent by the consumer matches the one kept in the state of the producer, it is considered as successful and discarded, and the consumer can send the next event. Otherwise, the same message is sent again until an acknowledgement is received.

## Usage

**Note:** the default logger level is `:debug`

First, declare a module

```elixir
defmodule MyModule do
  use Sandbox
  
  def start_link(_opts) do
    Sandbox.start_link(__MODULE__, [])
  end
end
```

Then start it

```
iex> {:ok, _} = MyModule.start_link([])
{:ok, #PID<0.202.0>}

iex> MyModule.publish("Hello World")
:ok

[debug] Publish message #8511ac3f-cd5b-4bdd-8cb5-d93ef2d71c45
[debug] Processing message #8511ac3f-cd5b-4bdd-8cb5-d93ef2d71c45
[debug] Received ack for message #8511ac3f-cd5b-4bdd-8cb5-d93ef2d71c45
```

If you want to see message republish in action, try this:

```
for i <- 1..10, do: Foo.publish("Message #{i}")
Foo.consumer_name() |> Process.whereis() |> Process.exit(:kill)
```
