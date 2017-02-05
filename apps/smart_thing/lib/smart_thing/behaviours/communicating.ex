defmodule Marvin.SmartThing.Communicating do

	alias Marvin.SmartThing.Device

	@doc "A name to give to the communicator device's  port"
	@callback port() :: binary
	
	@doc "Broadcast info to all other smart things in the community"
	@callback broadcast(device :: %Device{}, info :: any) :: any

	@doc "Send a percept to a member of the parent community"
	@callback report_up(device :: %Device{}, about :: any, value :: any) :: any

	@doc "The senses that become attended to when a given sense is also attended to"
	@callback senses_awakened_by(sense :: any) :: [any]

		
end
