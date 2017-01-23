defmodule Marvin.SmartThing.PFCortexHandler do

	@moduledoc "Pre-frontal cortex even handler"

	use GenEvent
	require Logger

	alias Marvin.SmartThing.PFCortex

	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, %{}}
	end

	def handle_event(:tick, state) do
		PFCortex.tick()
		{:ok, state}
	end

end
