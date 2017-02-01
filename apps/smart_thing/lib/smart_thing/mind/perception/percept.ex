defmodule Marvin.SmartThing.Percept do
  @moduledoc "A struct for a percept (a unit of perception)."
	
	import Marvin.SmartThing.Utils

	@doc """
  about: What is being perceived
  value: The measurement/value of the perception (a number, atom etc.)
  since: When the perception happened
  until: Time at which the perception is still unchanged
  source: The source of the perception (a detector or perceptor)
  ttl: How long the percept is to be retained in memory
  resolution: The precision of the detector or perceptor. Nil if perfect resolution.
  transient: If true, the percept will not be memorized
  """
	defstruct about: nil, value: nil, since: nil, until: nil, source: nil, ttl: nil, resolution: nil, transient: false

	@doc "Create a new percept with sense and value set"
	def new(about: sense, value: value) do
		msecs = now()
		%Marvin.SmartThing.Percept{about: sense,
															 since: msecs,
															 until: msecs,
															 value: value}
	end

	@doc "Create a new percept with sense, value set"
	def new_transient(about: sense, value: value) do
		msecs = now()
		%Marvin.SmartThing.Percept{about: sense,
															 since: msecs,
															 until: msecs,
															 value: value,
							 								 transient: true}
	end

	@doc "Get the sense name, whether the sense is qualified or not"
	def unqualified_sense(%Marvin.SmartThing.Percept{about: {sense_name, _qualifier}}) do
		sense_name
	end

	def unqualified_sense(%Marvin.SmartThing.Percept{about: sense}) do
		sense
	end

	@doc "Get the sense qualifier, nil if none"
	def sense_qualifier(%Marvin.SmartThing.Percept{about: {_sense_name, qualifier}}) do
		qualifier
	end

	def sense_qualifier(%Marvin.SmartThing.Percept{}) do
		nil
	end

	@doc "Set the source"
	def source(percept, source) do
		%Marvin.SmartThing.Percept{percept | source: source}
	end
	
	@doc "Are two percepts essentially the same (same sense, value and source)?"
	def same?(percept1, percept2) do
		percept1.about == percept2.about
		and percept1.value == percept2.value
		and percept1.source == percept2.source
	end

  @doc "The age of the percept"
  def age(percept) do
    now() - percept.until
  end

	@doc "The sense of the percept"
	def sense(percept) do
		case percept.about do
			{sense, _qualifier}
				-> sense
			sense when is_atom(sense)
				-> sense
		end
	end

  # about, since and value are required for the percept to be memorable
	
end
