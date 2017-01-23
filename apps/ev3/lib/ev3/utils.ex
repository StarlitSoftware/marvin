defmodule Marvin.Ev3.Utils do
	@moduledoc "Utility functions"

	@doc "The time now in msecs"
	def get_voice() do
		get_robot_setting(:voice, "en")
	end

	def get_beacon_channel() do
		get_robot_setting(:beacon_channel, 0)
  end

  @doc "Get personal setting "
  def get_robot_setting(setting, default_value) do
    settings = Application.get_env(:ev3, :robot)
		Keyword.get(settings, setting, default_value)
  end

end
