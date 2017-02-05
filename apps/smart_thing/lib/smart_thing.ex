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

	def start_platform() do
		platform_dispatch(:start)
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

	def perception_logic() do
		profile_dispatch(:perception_logic)
	end

	def motivation_logic() do
		profile_dispatch(:motivation_logic)
	end

	def behavior_logic() do
		profile_dispatch(:behavior_logic)
	end

	def actuation_logic() do
		platform_dispatch(:actuation_logic)
	end

	def id_channel() do
		platform_dispatch(:id_channel)
	end

	def senses_for_id_channel(id_channel) do
		platform_dispatch(:senses_for_id_channel, [id_channel])
	end
	
end
