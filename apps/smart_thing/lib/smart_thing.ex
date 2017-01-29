defmodule Marvin.SmartThing do

	import Marvin.SmartThing.Utils, only: [platform_dispatch: 1]

	@doc "Whether in test mode"
	def testing?() do
		Application.get_env(:smart_thing, :mock)
	end

	def sensors() do
		if Marvin.SmartThing.testing?() do
			[Mock.TouchSensor.new(),
       Mock.ColorSensor.new(),
       Mock.InfraredSensor.new(),
       Mock.UltrasonicSensor.new(),
       Mock.GyroSensor.new()]
		else
			platform_dispatch(:sensors)
		end
  end

	def motors() do
		if Marvin.SmartThing.testing?() do
			[Mock.Tachomotor.new(:large, "outA"),
			 Mock.Tachomotor.new(:large, "outB"),
			 Mock.Tachomotor.new(:medium, "outC")]
    else
			platform_dispatch(:motors)
		end
	end

	@doc "Nudge the value of a sense from a mock device"
	def nudge(%Device{mock: true} = device, sense, value, previous_value) do 
	    apply(module_for(device), :nudge, [device, sense, value, previous_value])
	end

end
