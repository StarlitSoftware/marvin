defmodule Marvin.SmartThing.ProfileBehaviour do

	@moduledoc "Behaviour for a profile"

	@doc "Perceptor configs"
	@callback perceptor_configs() :: [any]

	@doc "Motivator configs"
	@callback motivator_configs() :: [any]

	@doc "Behavior configs"
	@callback behavior_configs() :: [any]

end
	
