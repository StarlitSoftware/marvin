defmodule Marvin.SmartThing.Device do
  @moduledoc "Data specifying a motor, sensor or LED."
  
  @doc """
  mod - Module that implements the device
  class - :sensor, :motor, :led, :sound etc.
  path - sys file where to read/write to interact with device
  port - the name of the port the device is connected to
  type - the type of motor, sensor or led
  props - idiosyncratic properties of the device
  mock - whether this is a mock device or a real one
  """
  defstruct mod: nil, class: nil, path: nil, port: nil, type: nil, props: %{}, mock: false

  def mode(%Marvin.SmartThing.Device{mod: mod, type: type}) do
		apply(mod, :mode, [type])
	end
	
  def device_code(%Marvin.SmartThing.Device{mod: mod, type: type}) do
		apply(mod, :device_code, [type])
	end

	def name(%Marvin.SmartThing.Device{path: path}) do
		path
	end
	
end
