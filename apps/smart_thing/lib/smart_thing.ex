defmodule Marvin.SmartThing do

	alias Marvin.SmartThing.Communicators
	import Marvin.SmartThing.Utils, only: [platform_dispatch: 1, platform_dispatch: 2, profile_dispatch: 1]
	

	def platform() do
		platform_name = System.get_env("MARVIN_PLATFORM") || "mock_ev3"
		platforms = Application.get_env(:smart_thing, :platforms)
    Map.get(platforms, platform_name)
	end

	def profile() do
		profile_name = System.get_env("MARVIN_PROFILE") || "puppy"
		profiles = Application.get_env(:smart_thing, :profiles)
    Map.get(profiles, profile_name)
	end

	def community_name() do
		System.get_env("MARVIN_COMMUNITY") || "lego"
	end

	def peer() do
		(System.get_env("MARVIN_PEER") || "???") |> String.to_atom()
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

	def perceptor_configs() do
		profile_dispatch(:perceptor_configs)
	end

	def motivator_configs() do
		profile_dispatch(:motivator_configs)
	end

	def behavior_configs() do
		profile_dispatch(:behavior_configs)
	end

	def actuator_configs() do
		platform_dispatch(:actuator_configs)
	end

	def id_channel() do
		platform_dispatch(:id_channel)
	end

	def senses_for_id_channel(id_channel) do
		platform_dispatch(:senses_for_id_channel, [id_channel])
	end
	
end
