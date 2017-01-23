defmodule Marvin.SmartThing.PFCortex do

	@moduledoc "Pre-frontal cortex. Responsible for focus. Polls only the sensors that senses what matters here and now"

	require Logger

	@name __MODULE__

	def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	def init(_) do
    {:ok, %{}}
	end

	def tick() do
		# TODO - Poll all sensors that matter here and now
	end

	


end
