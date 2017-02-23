defmodule Marvin.SmartThing.DetectorsHandler do
  @moduledoc "The detectors event handler"
	
	require Logger
	use GenEvent
	alias Marvin.SmartThing.{Device, Detector}
	
	def init(_) do
		Logger.info("Starting #{__MODULE__}")
		{:ok, %{}}
	end

	def handle_event({:poll, sensing_device, sense}, state) do
		Detector.poll(Device.name(sensing_device), sense)
		{:ok, state}
	end

	def handle_event(_event, state) do
#		Logger.debug("#{__MODULE__} ignored #{inspect event}")
		{:ok, state}
	end

end
