defmodule Marvin.SmartThing.AttentionHandler do

	@moduledoc "Pre-frontal cortex event handler"
	
	use GenEvent
	require Logger

	alias Marvin.SmartThing.Attention

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, %{}}
	end

	def handle_event(:tick, state) do
		Attention.tick()
		{:ok, state}
	end

	def handle_event({:motivated, _motive}, state) do
		Attention.reset()
		{:ok, state}
	end

	def handle_event({:behavior_stopped, _name, reflex?}, state) do
		if not reflex?, do: Attention.reset()
		{:ok, state}
	end

	def handle_event({:behavior_transited, _behavior_name, _to_state_name}, state) do
		Attention.reset()
		{:ok, state}
	end

	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
