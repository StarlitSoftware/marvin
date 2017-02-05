defmodule Marvin.SmartThing.Utils do

	@moduledoc "Utility functions"

	alias Marvin.SmartThing

	@doc "The time now in msecs"
	def now() do
		{mega, secs, micro} = :os.timestamp()
		((mega * 1_000_000) + secs) * 1000 + div(micro, 1000)
	end

  @doc "Supported time units"
  def units() do
    [:msecs, :secs, :mins, :hours]
  end

	@doc "Convert a duration to msecs"
	def convert_to_msecs(nil), do: nil
	def convert_to_msecs({count, unit}) do
		case unit do
			:msecs -> count
			:secs -> count * 1000
			:mins -> count * 1000 * 60
			:hours -> count * 1000 * 60 * 60
		end
	end

	def platform_dispatch(fn_name) do
		platform_dispatch(fn_name, [])
	end
	
	def platform_dispatch(fn_name, args) do
		apply(SmartThing.platform(), fn_name, args)
	end

	def profile_dispatch(fn_name) do
		profile_dispatch(fn_name, [])
	end
	
	def profile_dispatch(fn_name, args) do
		apply(SmartThing.profile(), fn_name, args)
	end

	def get_voice() do
		platform_dispatch(:voice)
	end
	
	def pg2_group() do
		Application.get_env(:smart_thing, :group)
	end
	
end
