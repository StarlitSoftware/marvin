defmodule Marvin.Mommy.Motivation do
	@moduledoc "A mommy's motivation"

	alias Marvin.SmartThing.{MotivatorConfig, Motive, Percept}

	def motivator_configs() do
		[
			# A maternal instinct motivator
			MotivatorConfig.new(
				name: :maternal_instinct,
				focus: %{senses: [:time_elapsed], motives: [], intents: []},
				span: nil,
				logic: maternal_instinct()
			)
		]
	end

	@doc "Maternal instinct motivation"
	def maternal_instinct() do
		fn
		(%Percept{about: :time_elapsed}, _) ->
				Motive.on(:maternal_instinct) # never turned off (of course)
		end
	end

end
