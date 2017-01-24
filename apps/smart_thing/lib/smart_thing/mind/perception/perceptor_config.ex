defmodule Marvin.SmartThing.PerceptorConfig do
	@moduledoc "A perceptor's configuration"

	import Marvin.SmartThing.Utils

	defstruct name: nil, focus: nil, ttl: nil, span: nil, logic: nil

	@doc "Make a new perceptor configuration"
	def new(name: name,
					focus: %{senses: _senses, motives: _motives, intents: _intents} = focus,
					span: span, # composed from percepts no older than span msecs
					ttl: ttl, # how long the percept will be retained in memory in msecs
					logic: logic) do
		%Marvin.SmartThing.PerceptorConfig{name: name,
																			 focus: focus,
																			 span: convert_to_msecs(span),
																			 ttl: convert_to_msecs(ttl) ,
																			 logic: logic}
	end

end
