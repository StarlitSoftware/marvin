defmodule Marvin.SmartThing do

	@doc "Whether in test mode"
	def testing?() do
		Application.get_env(:smart_thing, :mock)
	end

  @doc "The runtime platform. Returns one of :brickpi, :ev3, :dev"
  def platform() do
		Application.get_env(:smart_thing, :platform)
  end

end
