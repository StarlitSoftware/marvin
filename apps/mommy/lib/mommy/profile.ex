defmodule Marvin.Mommy.Profile do
	
	@moduledoc "A mommy's profile"

	@behaviour Marvin.SmartThing.ProfileBehaviour

	def perception_logic() do
		Marvin.Mommy.Perception.perceptor_configs()
	end

	def motivation_logic() do
		Marvin.Mommy.Motivation.motivator_configs()
	end

	def behavior_logic() do
		Marvin.Mommy.Behaviors.behavior_configs()
	end

end
