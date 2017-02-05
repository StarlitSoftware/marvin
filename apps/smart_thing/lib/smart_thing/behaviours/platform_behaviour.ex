defmodule Marvin.SmartThing.PlatformBehaviour do

	@doc "Starts the platform"
	@callback start() :: :ok | {:error, binary}

	@doc "Translates a generic device type to the platform's device type"
	@callback mode(device_type :: atom) :: binary

	@doc "Translates a generic device code to the platform's device code"
  @callback device_code(device_type :: atom) :: binary

	@doc "Gives a list of connected sensor devices"
	@callback sensors() :: [%Marvin.SmartThing.Device{}]

	@doc "Give a list of connected motor devices"
	@callback motors() :: [%Marvin.SmartThing.Device{}]

	@doc "Give a list of connected sound devices"
	@callback sound_players() :: [%Marvin.SmartThing.Device{}]

	@doc "Give a list of connected LED devices"
	@callback lights() :: [%Marvin.SmartThing.Device{}]

	@doc "Shuts the device down"
	@callback shutdown() :: any

	@doc "A channel identifying the smart thing"
	@callback id_channel() :: any

	@doc "Returns the platform's devce manager for the given type"
	@callback device_manager(type :: atom) :: any

  @doc "Get the voice to be used to speak"
	@callback voice() :: binary

	@doc "Read a sensor's sense"
	@callback sensor_read_sense(devce :: %Marvin.SmartThing.Device{}, sense :: any) :: any

	@doc "Get a sensor's sensitivity for a sense"
	@callback sensor_sensitivity(device :: %Marvin.SmartThing.Device{}, sense :: any) :: any
	
	@doc "Read a motor's sense"
	@callback motor_read_sense(device :: %Marvin.SmartThing.Device{}, sense :: any) :: any

	@doc "Get a motor's sensitivity for a sense"
	@callback motor_sensitivity(device :: %Marvin.SmartThing.Device{}, sense :: any) :: any

	@doc "Get a list of senses associated with a smart thing's id channel"
  @callback senses_for_id_channel(id_channel :: binary) :: [any]

	@doc "Nudge the current sensed value, if appropriate"
	@callback nudge(device :: %Marvin.SmartThing.Device{}, sense :: any, value :: any, previous_value :: any) :: any

	@doc "The actuation logic as actuator configs"
	@callback actuation_logic() :: [any]
	
end
