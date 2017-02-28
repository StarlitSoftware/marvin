defmodule Marvin.SmartThing.InternalClock do
  @moduledoc "An internal clock"

  require Logger
  alias Marvin.SmartThing.Percept
  alias Marvin.SmartThing.CNS
  import Marvin.SmartThing.Utils

  @name __MODULE__

  def start_link() do
    {:ok, pid} = Agent.start_link(
      fn() ->
        %{responsive: false, tock: nil, count: 0}
      end,
      [name: @name]
    )
		spawn_link(fn() ->
			:timer.sleep(tick_interval())
			tick_tock()
		end)
		Logger.info("#{@name} started")
    {:ok, pid}
  end

  def tick() do
    Agent.cast(
      @name,
      fn(state) ->
        if state.responsive do
          tock = now()
          Logger.info("tick")
					CNS.notify_tick()
          Percept.new_transient(about: :time_elapsed,
																value: %{delta: tock - state.tock, count: state.count})
          |> CNS.notify_perceived()
          %{state | tock: tock, count: state.count + 1}
        else
					Logger.info(" no tick")
          state
        end
      end)
  end

    @doc "Stop the generation of clock tick percepts for a set duration (msecs)"
  def pause() do
		Agent.update(
			@name,
			fn(state) ->
        Logger.info("Pausing clock")
				  %{state | responsive: false}
			end)
  end

  @doc "Resume producing percepts"
	def resume() do
    Logger.info("Resuming clock")
		Agent.update(
			@name,
			fn(state) ->
				%{state | responsive: true, tock: now()}
			end)
	end

	### Private

	defp tick_tock() do
		:timer.sleep(tick_interval())
		tick()
		tick_tock()
	end

end
