defmodule Marvin.SmartThing.Utils do

	@moduledoc "Utility functions"

	alias Marvin.SmartThing

	def timeout() do
		10000
	end

	def tick_interval() do
		Application.fetch_env!(:marvin, :tick_interval)
	end

	def max_percept_age() do
		Application.fetch_env!(:marvin, :max_percept_age)
	end

	def max_motive_age() do
		Application.fetch_env!(:marvin, :max_motive_age)
	end

	def max_intent_age() do
		Application.fetch_env!(:marvin, :max_intent_age)
	end

	def strong_intent_factor() do
		Application.fetch_env!(:marvin, :strong_intent_factor)
	end

	def max_beacon_channels() do
		Application.fetch_env!(:marvin, :max_beacon_channels)
	end		

	def very_fast_rps() do
		Application.fetch_env!(:marvin, :very_fast_rps)
	end		

	def fast_rps() do
		Application.fetch_env!(:marvin, :fast_rps)
	end		

	def normal_rps() do
		Application.fetch_env!(:marvin, :normal_rps)
	end		

	def slow_rps() do
		Application.fetch_env!(:marvin, :slow_rps)
	end		

	def very_slow_rps() do
		Application.fetch_env!(:marvin, :very_slow_rps)
	end		

	@doc "The time now in msecs"
	def now() do
		div(:os.system_time(), 1_000_000)
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
		System.get_env("MARVIN_COMMUNITY") || "lego"
	end
	
end
