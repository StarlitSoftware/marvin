defmodule Marvin.SmartThing.MemoryHandler do
	@moduledoc "The memory of percepts"

	use GenEvent
	require Logger
	alias Marvin.SmartThing.Memory

  ### Callbacks
	
	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, []}
	end

	def handle_event({:perceived, percept}, state) do
		if not percept.transient do
			Memory.store(percept)
		end
		{:ok, state}
	end

	def handle_event({:motivated, motive}, state) do
		Memory.store(motive)
		{:ok, state}
	end

	# Intends are memorized only when realized by actuators
	# {:intended, intent} events are ignored
	def handle_event({:realized, _actuator_name, intent}, state) do
		Memory.store(intent)
		{:ok, state}
	end

	def handle_event({:behavior_stopped, name, reflex?}, state) do
		if not reflex?, do: Memory.store_behavior_stopped(name)
		{:ok, state}
	end

	def handle_event({:behavior_started, name, reflex?}, state) do
		if not reflex?, do: Memory.store_behavior_started(name)
		{:ok, state}
	end

	def handle_event({:behavior_transited, behavior_name, to_state_name}, state) do
		Memory.store_behavior_transited(behavior_name, to_state_name)
		{:ok, state}
	end


	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
