defmodule Marvin.SmartThing.Communicating do

	alias Marvin.SmartThing.Device
	
	@doc "Communicate info to other robots in a team"
	@callback communicate(device :: %Device{}, info :: any, team :: atom) :: %Device{}

end
