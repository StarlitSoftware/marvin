defmodule Marvin.SmartThing.Attention do

	@moduledoc "Responsible for attention. On each clock tick, polls only the sensors that senses what matters here and now"

	require Logger
	alias Marvin.SmartThing.{Detector, Motivation, Motive, Behaviors, Perception}
	alias Marvin.SmartThing

	@name __MODULE__

	def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	def tick() do
		GenServer.call(@name, :tick)
	end

	def reset() do
		GenServer.call(@name, :reset)
	end

	### Callbacks

	def init(_) do
		sensing_devices = SmartThing.sensors() ++ SmartThing.motors()
    {:ok, %{sensing_devices: sensing_devices,
						motivator_configs: Motivation.motivator_configs(),
						behavior_configs: Behaviors.behavior_configs(),
						perceptor_configs: perceptor_configs,
						perceptible_senses: Perception.perceptor_configs(),
						detected_senses: detected_senses(sensing_devices) 
						attended_senses: nil} # cached here, uncached on motivation and behavior events # TODO
		}
	end
	
  def handle_call(:tick, %{sensing_devices: sensing_devices}, state) do
		attended_senses = find_attended_senses(state)
		Enum.each(sensing_devices,
			fn(sensing_device) ->
				device_senses = apply(sensing_device.mod, :senses, [])
				if Enum.any?(device_senses, &(&1 in attended_senses)) do # todo - deal with {:beacon_heading, 2} etc.
					Process.spawn(fn() -> Detector.poll(Device.name(sensing_device)) end, [:link])
				end)
		{:reply, :ok, %{state | attended_senses: attended_senses}}
	end

	def handle_call(:reset, state) do
		{:reply, :ok, %state | attended_senses: nil}
	end

	### Private

	defp detected_senses(sensing_devices) do
		Enum.reduce(sensing_devices,
								[],
			fn(sensing_device, acc) ->
				apply(sensing_device.mod, :senses, []) ++ acc
			end) |> Enum.uniq()
	end
	
	# The senses that directly or indirectly (via derived percepts) can:
	# Turn off an on motive
	# Turn on an uninhibited motive
	# Cause a behavior state transition
	defp find_attended_senses(%{attended_events: attended_events, detected_senses: detected_senses} = _state) do
	  if attended_events != nil do
			attended_events
		else
			on_motives = Memory.on_motives()
			top_attended_senses = attended_motive_senses(on_motives, state.motivator_configs)
			++ attended_behavior_senses(on_motives, state.motivator_configs, state.behavior_configs)
			Enum.reduce(top_attended_senses,
									[],
				fn(top_sense, acc) ->
					detected_senses_for(top_sense, state.perceptor_configs, detected_senses) ++ acc
				end) |> Enum.uniq()
		end
	end

	defp attended_motive_senses(on_motives, motivator_configs) do
		unhibited_motive_names = Enum.select(all_motive_names(motivator_configs),
			fn(motive_name) ->
				not Enum.any?(on_motives, &(motive_name in &1.inhibits))
		)
		motive_senses = Enum.reduce(uninhibited_motive_names,
																[],
			fn(motive_name, acc) ->
				acc ++ motive_focus_senses(motive_name, motivator_configs)
			end) |> Enum.uniq()
	end

	defp all_motive_names(motivator_configs) do
		Enum.map(motivator_configs, &(&1.name))
	end

	defp motivator_focus_senses(motivator_name, motivator_configs) do
		motive_config = Enum.find(motivator_configs, &(&1.name == motivator_name))
		motive_config.focus.senses
	end

	defp attended_behavior_senses(on_motives, motivator_configs, behavior_configs) do
		reflex_behavior_names = reflex_behavior_names(behavior_configs)
		transited_behavior_names = Memory.active_behavior_names() #i.e. transited
		inhibited_motives_names = inhibited_motive_names(on_motives, motivator_configs)
		active_behavior_names = Enum.reject(transited_behavior_names,
			fn(behavior_name) ->
				Enum.any?(inhibited_motive_names, &(behavior_motivated_by?(behavior_name, &1, behavior_configs)))
			end)
		Enum.reduce(reflex_behavior_names ++ active_behavior_names,
								[],
			fn(behavior_name, acc) ->
				acc ++ behavior_focus_senses(behavior_name, behavior_configs)
			end) |> Enum.uniq()
	end

	
	defp reflex_behavior_names(behavior_configs) do
		Enum.filter_map(behavior_configs,
										&(&1.motivated_by == []),
										&(&1.name))
	end

	defp behavior_focus_senses(behavior_name, behavior_configs) do
		behavior_config = Enum.find(behavior_configs, &(&1.name == behavior_name))
		behavior_config.senses
	end

	defp behavior_motivated_by?(behavior_name, motive_name, behavior_configs) do
		motivators = Enum.find(behavior_configs(), &(&1.name == behavior_name)).motivated_by
		motive_name in motivators
	end

	defp inhibited_motive_names(on_motives, motivator_configs) do # get the names of all motives inhibited by any of the on motives
		Enum.reduce(Memory.on_motives(),
								[],
			fn(on_motive, acc) ->
				acc ++ on_motive.inhibits
			end)
	end

	defp detected_senses_for(sense, perceptor_configs, detected_senses) do
		expand_senses(sense, perceptor_configs,  [])
		|> Enum.uniq
		|> Enum.filter(&(&1 in detected_senses))
	end

	defp expand_sense(sense, perceptor_configs, results) do
		case perceptor_config_named(sense, perceptor_configs) do
			nil ->
				results,
			perceptor_config ->
				case Enum.reject(perceptor_config.focus.senses, &(&1 in results)) do
					[] ->
						results
					sub_senses ->
						Enum.reduce(sub_senses,
												results ++ sub_senses,
							fn(sub_sense, acc) ->
								acc ++ expand_sense(sub_sense, perceptor_configs, acc)
							end)
				end
		end
	end

	defp perceptor_config_named(sense, perceptor_configs) do
		Enum.find(perceptor_configs, &(&1 == sense))
	end				

end
