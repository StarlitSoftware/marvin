defmodule Marvin.SmartThing.MotivatorsHandler do
  @moduledoc "The motivators event handler"
	
	require Logger
	use GenEvent
	alias Marvin.SmartThing.{Motive, Motivator, CNS, Percept}
	alias Marvin.SmartThing
	
	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		motivator_configs = SmartThing.motivation_logic()
		{:ok, %{motivator_configs: motivator_configs}}
	end

	def handle_event({:perceived, percept}, state) do
		process_percept(percept, state)
		{:ok, state}
	end

	def handle_event(_event, state) do
		# Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

	### Private

	defp process_percept(percept, %{motivator_configs: motivator_configs}) do
		motivator_configs
		|> Enum.filter(&(Percept.sense(percept) in &1.focus.senses))
		|> Enum.each(
			fn(motivator_config) ->
				Process.spawn( # allow parallelism
					fn() ->
						case Motivator.react_to_percept(motivator_config.name, percept) do
							nil -> :ok
							%Motive{} = new_motive ->
								CNS.notify_motivated(%{new_motive | source: motivator_config.name})
						end
					end,
					[:link])
			end)
	end

end
