defmodule Marvin.SmartThing.Attention do

	@moduledoc "Responsible for attention. On each clock tick, polls only the sensors that senses what matters here and now, unless already in the midst of a polling run."

	require Logger
	alias Marvin.SmartThing.{Device, Detector, Motivation, Behaviors, Perception, Memory}
	alias Marvin.SmartThing

	@name __MODULE__

	def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	@doc "Poll all currently meaningful senses, unless already polling"
	def tick() do
		GenServer.cast(@name, :tick)
	end

	@doc "Reset attended_senses to nil so they are recomputed when needed"
	def reset() do
		GenServer.cast(@name, :reset)
	end

	def terminate(reason, _state) do
		Logger.warn("#{@name} terminating: #{inspect reason}")
	end

	### Callbacks

	def init(_) do
		sensing_devices = SmartThing.sensors() ++ SmartThing.motors()
    {:ok, %{# static
				    sensing_devices: sensing_devices,
						motivator_configs: Motivation.motivator_configs(),
						behavior_configs: Behaviors.behavior_configs(),
						perceptor_configs: Perception.perceptor_configs(),
						detected_senses: detected_senses(sensing_devices),
						# dynamic
						attended_senses: nil,
						polling: false}
		}
	end
	
  def handle_cast(:tick, %{polling: polling?} = state) do
		if polling? do
			Logger.info("TICK: already polling")
			{:noreply, state}
		else
			Logger.info("TICK: polling")
			attended_senses = find_attended_senses(state)
			spawn_link(fn() -> detect(attended_senses, state) end)
		  {:noreply, %{state | polling: true, attended_senses: attended_senses}}
		end
		
	end
	def handle_cast(:reset, state) do
		{:noreply, %{state | attended_senses: nil}}
	end

	def handle_info(:polling_completed, state) do
		{:noreply, %{state | polling: false}}
	end

	### Private

	defp detect(attended_senses, %{sensing_devices: sensing_devices} = _state) do
		Enum.each(sensing_devices,
			fn(sensing_device) ->
				device_senses = apply(sensing_device.mod, :senses, [sensing_device])
				Enum.each(device_senses,
					fn(device_sense) ->
						if device_sense in attended_senses do
							Detector.poll(Device.name(sensing_device), device_sense)
						end
					end)
			end)
		send(@name, :polling_completed) # "out of band" message to set polling state to false
	end

	defp detected_senses(sensing_devices) do
		Enum.reduce(sensing_devices,
								[],
			fn(sensing_device, acc) ->
				apply(sensing_device.mod, :senses, [sensing_device]) ++ acc
			end) |> Enum.uniq()
	end
	
	# The senses that directly or indirectly (via derived percepts) can:
	# Turn on/off an uninhibited motive
	# Cause a behavior state transition (reflex or motivated)
	defp find_attended_senses(%{motivator_configs: motivator_configs,
															behavior_configs: behavior_configs,
															perceptor_configs: perceptor_configs,
															attended_senses: attended_senses,
															detected_senses: detected_senses} = _state) do
	  if attended_senses != nil do
			attended_senses
		else
			on_motives = Memory.on_motives()
			top_attended_senses = attended_motive_senses(on_motives, motivator_configs) ++
				attended_behavior_senses(on_motives, behavior_configs)
			Enum.reduce(top_attended_senses,
									[],
				fn(top_sense, acc) ->
					detected_senses_for(top_sense, perceptor_configs, detected_senses) ++ acc
				end) |> Enum.uniq()
		end
	end

	defp attended_motive_senses(on_motives, motivator_configs) do
		uninhibited_motive_names = Enum.filter(all_motive_names(motivator_configs),
			fn(motive_name) ->
				Enum.any?(on_motives, &(motive_name in &1.inhibits))
			end)
		Enum.reduce(uninhibited_motive_names,
								[],
			fn(motive_name, acc) ->
				acc ++ motivator_focus_senses(motive_name, motivator_configs)
			end) |> Enum.uniq()
	end

	defp all_motive_names(motivator_configs) do
		Enum.map(motivator_configs, &(&1.name))
	end

	defp motivator_focus_senses(motivator_name, motivator_configs) do
		motive_config = Enum.find(motivator_configs, &(&1.name == motivator_name))
		motive_config.focus.senses
	end

	defp attended_behavior_senses(on_motives, behavior_configs) do
		reflex_behavior_names = reflex_behavior_names(behavior_configs)
		transited_behavior_names = Memory.transited_behavior_names() #i.e. just transited and not stopped
		inhibited_motive_names = inhibited_motive_names(on_motives)
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
		motivator_names = Enum.find(behavior_configs, &(&1.name == behavior_name)).motivated_by
		motive_name in motivator_names
	end

	defp inhibited_motive_names(on_motives) do # get the names of all motives inhibited by any of the on motives
		Enum.reduce(on_motives,
								[],
			fn(on_motive, acc) ->
				acc ++ on_motive.inhibits
			end)
	end

	defp detected_senses_for(sense, perceptor_configs, detected_senses) do
		expand_sense(sense, perceptor_configs,  [])
		|> Enum.uniq
		|> Enum.filter(&(&1 in detected_senses))
	end

	defp expand_sense(sense, perceptor_configs, results) do
		case perceptor_config_named(sense, perceptor_configs) do
			nil ->
				results
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
