defmodule Marvin.SmartThing do

	alias Marvin.SmartThing.Communicators
	import Marvin.SmartThing.Utils, only: [platform_dispatch: 1, platform_dispatch: 2]
	
	@doc "Whether in test mode"
	def testing?() do
		Application.get_env(:smart_thing, :mock)
	end

	def platform() do
		if testing?() do
			Application.get_env(:smart_thing, :mock_platform)
		else
			Application.get_env(:smart_thing, :platform)
		end
	end

	def sensors() do
		platform_dispatch(:sensors)
	end

	def motors() do
		platform_dispatch(:motors)
	end

	def leds() do
		platform_dispatch(:leds)
	end

	def sound_players() do
		platform_dispatch(:sound_players)
	end

	def communicators() do
		Communicators.communicators()
	end

	def actuator_configs() do
		platform_dispatch(:actuator_configs)
	end

	def id_channel() do
		platform_dispatch(:id_channel)
	end

	def nodes() do
		Application.get_env(:smart_thing, :nodes)
	end

	def senses_for_id_channel(id_channel) do
		platform_dispatch(:senses_for_id_channel, [id_channel])
	end
	
end
