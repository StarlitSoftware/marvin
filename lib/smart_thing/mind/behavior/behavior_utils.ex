defmodule Marvin.SmartThing.BehaviorUtils do
	@moduledoc "Behavior utilities"

	alias Marvin.SmartThing.{Intent, CNS}

	require Logger

	def generate_strong_intent(about, value \\ nil) do
		generate_intent(about, value, true)
	end

	def generate_intent(about) do
    generate_intent(about, nil)
  end
  
  def generate_intent(about, value, strong? \\ false) do
    if strong? do
      Intent.new_strong(about: about, value: value)
    else
      Intent.new(about: about, value: value)
    end
    |> CNS.notify_intended()
  end

	def nothing() do
		fn(_percept, _state) ->
			Logger.info("Doing NOTHING")
		end
	end

end
