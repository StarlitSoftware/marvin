defmodule Marvin.SmartThing.ActuatorsHandler do
  @moduledoc "The actuators event handler"
	
	require Logger
	use GenEvent

	alias Marvin.SmartThing.{Actuator}
	alias Marvin.SmartThing

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		actuator_configs = SmartThing.actuation_logic() # dispatches to platform
		{:ok, %{actuator_configs: actuator_configs}}
	end

	def handle_event({:intended, intent}, state) do
		process_intent(intent, state)
		{:ok, state}
	end

	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

	### Private

	defp process_intent(intent, %{actuator_configs: actuator_configs}) do
		actuator_configs
		|> Enum.filter(&(intent.about in &1.intents))
		|> Enum.each(
			fn(actuator_config) ->
				Process.spawn( # allow parallelism
					fn() ->
						Actuator.realize_intent(actuator_config.name, intent)
					end,
					[:link])
			end)
	end

end
