defmodule Marvin.Puppy.Profile do
	
	@moduledoc "A puppy's profile"

	@behaviour Marvin.SmartThing.ProfileBehaviour

	def perception_logic() do
		Marvin.Puppy.Perception.perceptor_configs()
	end

	def motivation_logic() do
		Marvin.Puppy.Motivation.motivator_configs()
	end

	def behavior_logic() do
		Marvin.Puppy.Behaviors.behavior_configs()
	end

end
