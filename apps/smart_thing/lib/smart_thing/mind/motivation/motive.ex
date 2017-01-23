defmodule Marvin.SmartThing.Motive do
	@moduledoc "A struct for a motive (a unit of motivation that's turned on or off)"

	import Marvin.SmartThing.Utils

	@doc """
  about: The name of the motive
	value: Either :on or :off
  details: Details about the motive (a map)
  since: When the motive got its current value
  inhibits: The names of the motives this one inhibits
  source: The source of the motive
  """
	defstruct about: nil, value: nil, details: %{}, since: nil, inhibits: [], source: nil

	@doc "Create an motive that's on"
	def on(name, details \\ %{}) do
	  %Marvin.SmartThing.Motive{about: name,
															since: now(),
															value: :on,
															details: details}
  end

	@doc "Create a motive that's off (to turn off an on motive of the same name)"
	def off(name, details \\ %{}) do
	  %Marvin.SmartThing.Motive{about: name,
															since: now(),
															value: :off,
															details: details}
  end

	@doc "Is the motive on?"
	def on?(motive) do
		motive.value == :on
	end
	
	@doc "Add an inhibition"
	def inhibit(motive, other_name) do
		if :all in motive.inhibits do
			motive
		else
			%Marvin.SmartThing.Motive{motive | inhibits: [other_name | motive.inhibits]}
		end
	end

	@doc "Add blanket inhibition"
	def inhibit_all(motive) do
		%Marvin.SmartThing.Motive{motive | inhibits: [:all]}
	end

	@doc "Whether a motive inhibits all others"
	def inhibits_all?(motive) do
		:all in motive.inhibits
	end

	@doc "The age of the motive"
  def age(motive) do
    fudge(now() - motive.since)
  end

  # A "memorable" - must have about, since and value fields

end							
