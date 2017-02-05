defmodule Marvin.SmartThing.Communicating do

	alias Marvin.SmartThing.Device

	@doc "A name to give to the communicator device's  port"
	@callback port() :: binary
	
	@doc "Broadcast info to all other smart things in the community"
	@callback broadcast(device :: %Device{}, info :: any) :: any

	@doc "Send info to a community member"
	@callback remote_send(to_node :: node(), info :: any, community_name :: binary) :: any

	@doc "The senses that become attended to when a given sense is also attended to"
	@callback senses_awakened_by(sense :: any) :: [any]

		
end
