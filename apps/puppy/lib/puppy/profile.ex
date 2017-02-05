defmodule Marvin.Puppy.Profile do
	
	@moduledoc "A puppy's profile"

	@behaviour Marvin.SmartThing.ProfileBehaviour

	def perceptor_configs() do
		Marvin.Puppy.Perception.perceptor_configs()
	end

	def motivator_configs() do
		Marvin.Puppy.Motivation.motivator_configs()
	end

	def behavior_configs() do
		Marvin.Puppy.Behaviors.behavior_configs()
	end

end
