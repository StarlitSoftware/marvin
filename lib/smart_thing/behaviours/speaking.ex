defmodule Marvin.SmartThing.Speaking do

	alias Marvin.SmartThing.Device

	@doc "The sound player says out loud the given words"
  @callback speak(sound_player :: %Device{}, words :: binary) :: %Device{}

end
