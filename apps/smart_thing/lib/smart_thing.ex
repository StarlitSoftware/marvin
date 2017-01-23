defmodule Marvin.SmartThing do

	@doc "Whether in test mode"
	def testing?() do
		Application.get_env(:smart_thing, :mock)
	end

end
