defmodule Marvin.Puppy.Perception do
	@moduledoc "Provides the configurations of all perceptors to be activated"

	import Marvin.SmartThing.MemoryUtils
	require Logger
	alias Marvin.SmartThing.{PerceptorConfig, Percept}

	## NOTE: Communication generates Percept.new(about: :heard, value: %{from: from_node, info: info, id_channel: id_channel, community: community_name})

	@doc "Give the configurations of all perceptors to be activated"
	def perceptor_configs() do
		[
				# A getting lighter/darker perceptor
				PerceptorConfig.new(
					name: :light,
					focus: %{senses: [:ambient], motives: [], intents: []},
					span: {10, :secs},
					ttl: {10, :secs},
					logic: light()),
				# A collision perceptor based on distance sensing
				PerceptorConfig.new(
					name: :collision,
					focus: %{senses: [:distance, :touch, :collision, :time_elapsed], motives: [], intents: []},
					span: nil, # no windowing
					ttl: {10, :secs}, # remember for 10 seconds
					logic: collision()),
				# Sensing danger
				PerceptorConfig.new(
					name: :danger,
					focus: %{senses: [:ambient, :collision, :danger, :time_elapsed], motives: [], intents: []},
					span: {10, :secs}, # only react to what happened in the last 10 seconds
					ttl: {30, :secs}, # remember for 30 secs
					logic: danger()),
				# Hunger pangs
				PerceptorConfig.new(
					name: :hungry,
					focus: %{senses: [:time_elapsed], motives: [], intents: [:eat]},
					span: {1, :mins},
					ttl: {30, :secs},
					logic: hungry()),
				# A food perceptor
				PerceptorConfig.new(
					name: :food,
					focus: %{senses: [:ambient, :color], motives: [], intents: []},
					span: {10, :secs},
					ttl: {30, :secs},
					logic: food()),
				# An odor perceptor
				PerceptorConfig.new(
					name: :scent,
					focus: %{senses: [:beacon_heading, :beacon_distance, :scent_strength], motives: [], intents: []},
					span: {10, :secs},
					ttl: {30, :secs},
					logic: scent()),
				# A food is near perceptor
				PerceptorConfig.new(
					name: :food_nearby,
					focus: %{senses: [:scent_strength], motives: [], intents: []},
					span: {10, :secs},
					ttl: {10, :secs},
					logic: food_nearby()),
				# A stuck perceptor
				PerceptorConfig.new(
					name: :stuck,
					focus: %{senses: [:beacon_distance], motives: [], intents: [:go_forward, :go_backward]},
					span: {10, :secs},
					ttl: {10, :secs},
					logic: stuck()),
        # A "someone is panicking and I am not in danger" perceptor
				PerceptorConfig.new(
					name: :other_panicking,
					focus: %{senses: [:heard, :danger], motives: [], intents: [:say_scared]},
					span: {10, :secs},
					ttl: {10, :secs},
					logic: other_panicking()),
        # A "someone is eating, I did not find food myself and I am hungry" perceptor
				# Also "I no longer hear some other eat that got me greedy" perceptor
				PerceptorConfig.new(
					name: :other_eating,
					focus: %{senses: [:heard, :food, :time_elapsed], motives: [], intents: []},
					span: {10, :secs},
					ttl: {10, :secs},
					logic: other_eating())       
		]
	end

  @doc "Find all senses used for perception"
  def used_senses() do
    perceptor_configs()
    |> Enum.map(&(Map.get(&1.focus, :senses, [])))
    |> List.flatten()
    |> MapSet.new()
    |> MapSet.to_list()
  end

	### Private

	def light() do
		fn
		(_percept, %{percepts: []}) -> nil
		(%Percept{about: :ambient, value: val}, %{percepts: percepts}) ->
				latest_ambient = last_memory(
							percepts,
							:ambient)
				cond do
					latest_ambient == nil -> 
						Percept.new(about: :light, value: :same)	  
					latest_ambient.value > val -> 
						Percept.new(about: :light, value: :lighter)	  
					latest_ambient.value < val -> 
						Percept.new(about: :light, value: :darker)	  
					true -> 
						Percept.new(about: :light, value: :same)	  
				end
		end
	end

	def food() do
		fn						 
		(_percept, %{percepts: []}) -> nil
			(%Percept{about: :color, value: :blue}, %{percepts: percepts}) ->
			if latest_memory?(
						percepts,
						:ambient,
						fn(value) -> value > 20  end) do
				Logger.info("!!!! FOOD a plenty !!!!")
			  Percept.new(about: :food, value: :plenty)
			else
				Logger.info("!!!! FOOD a little !!!!")
				Percept.new(about: :food, value: :little)
			end
				(%Percept{about: :color, value: _color}, _memories) ->
				Percept.new(about: :food, value: :none)
			(_, _) ->
				nil
		end
	end

	@doc "Is a collision soon, imminent or now?"
	def collision() do
		fn
		(_percept, %{percepts: []}) -> nil
		(%Percept{about: :touch, value: :pressed}, _memories) ->
					Percept.new(about: :collision, value: :now)
		(%Percept{about: :distance, value: n}, %{percepts: percepts}) when n < 10 ->
				if not any_memory?(
							percepts,
							:distance,
							1000,
							fn(value) -> value > 10 end) do
					Percept.new(about: :collision, value: :imminent)
				else
					Percept.new(about: :collision, value: :none)
				end
			(%Percept{about: :distance, value: val}, %{percepts: percepts}) ->
				approaching? = latest_memory?(
					percepts,
					:distance,
					fn(previous) -> val < previous  end)
				proximal? = all_memories?(
					percepts,
					:distance,
					5000,
					fn(value) -> value < 30 end)
				if approaching? and proximal? do
					Percept.new(about: :collision, value: :soon)
				else
					Percept.new(about: :collision, value: :none)
				end
			(%Percept{about: :touch, value: :released}, _memories) ->
					Percept.new(about: :collision, value: :none)
			(_, _) -> nil
		end
	end

	@doc "Danger, Will Robinson!"
	def danger() do
		fn
			(%Percept{about: :collision, value: :now}, %{percepts: percepts}) ->
				if all_memories?(
							percepts,
							:ambient,
							2000,
							fn(value) -> value < 10 end) do
					Percept.new(about: :danger, value: :high)
				else
					Percept.new(about: :danger, value: :low)
				end
		(%Percept{about: :time_elapsed}, %{percepts: percepts}) ->
				if not any_memory?(
							percepts,
							:danger,
							3000,
							fn(value) -> value in [:high, :low] end) do
					Percept.new(about: :danger, value: :none)
				else
					nil
				end
		(_,_) -> nil
		end
	end

	@doc "Is the robot hungry?"
	def hungry() do
		fn # Hunger based on time since last :eat intend
		(%Percept{about: :time_elapsed}, %{intents: intents}) ->
				how_full = summation(
				intents,
				:eat,
				30_000,
				fn(value) ->
					case value do
						:lots -> 5
						:some -> 3
					end
				end,
				0
			) # How much did I eat in the last 30 secs?
				cond do
					how_full > 10 -> Percept.new(about: :hungry, value: :not)
					how_full > 5 -> Percept.new(about: :hungry, value: :a_little)
					true -> Percept.new(about: :hungry, value: :very)
				end
			(_,_) -> nil
		end
	end

	@doc "Is the robot stuck?"
	def stuck() do 
	fn # Stuck if tried to go forward or backward for the last 5 secs and distances to beacon"
	(%Percept{about: {:beacon_distance, 1}, value: beacon_distance}, %{percepts: percepts, intents: intents}) ->
			forward_attempts = count(
			intents,
			about: :go_forward,
			since: 5_000,
			test: fn(_value) -> true end)
		  backward_attempts = count(
			intents,
			about: :go_backward,
			since: 5_000,
			test: fn(_value) -> true end)
			if (forward_attempts + backward_attempts) > 1 do
				average_beacon_distance = average(
					percepts,
					{:beacon_distance, 1},
					5_000,
					fn(value) -> value end,
					1000
				)
				beacon_distance_change = abs(average_beacon_distance - beacon_distance)
        {low, high} = range(
          percepts,
          :distance,
          5_000,
          fn(value) -> value end,
          {0, 1000}
        )
				if beacon_distance_change < 3 and (high - low) < 3 do
					Percept.new(about: :stuck, value: true)
				else
					Percept.new(about: :stuck, value: false)
				end
			else
				nil
			end
			(_ , _) ->
				nil
		end
	end

	@doc "Where's a beacon?"
	def scent() do
		fn
			(%Percept{about: {:beacon_distance, n}, value: value}, _memories) ->
				cond do
				value < 0 ->
					Percept.new(about: :scent_strength, value: {:unknown, n})
				value == 100 ->
					Percept.new(about: :scent_strength, value: {:very_weak, n})
				value > 50 ->
					Percept.new(about: :scent_strength, value: {:weak, n})
				value > 10 ->
					Percept.new(about: :scent_strength, value: {:strong, n})
				true ->
					Percept.new(about: :scent_strength, value: {:very_strong, n})
			end
		  (%Percept{about: {:beacon_heading, n}, value: heading}, %{percepts: percepts}) ->
        latest_scent_strength = last_memory(
				percepts,
				:scent_strength,
				fn({_, c}) -> c == n end)
			  latest_value = case latest_scent_strength do
											 nil ->
												 nil
											 %Percept{about: :scent_strength, value: {value, _}} ->
												 value
										 end
			cond do
				heading < -10 ->
					Percept.new(about: :scent_direction, value: {:left, abs(heading), latest_value, n})
				heading > 10 ->
					Percept.new(about: :scent_direction, value: {:right, abs(heading), latest_value, n})
				true ->
					Percept.new(about: :scent_direction, value: {:ahead, abs(heading), latest_value, n})
			end
			(_, _) ->
				nil
		end
	end

	# Is scent on channel of overheard eater either strong or very strong?
	def food_nearby() do
		fn
			(%Percept{about: :scent_strength, value: {strength, channel}}, %{memories: memories}) ->
				smelling_other_eating? = any_memory?(memories,
																						 :other_eating,
																						 2000,
				fn(%{id_channel: eater_channel, current: current?}) ->
					eater_channel == channel and current?
				end)																					 
				cond do
				strength in [:strong, :very_strong] and (channel == 1 or smelling_other_eating?) ->
					Percept.new(about: :food_nearby, value: channel)
				true ->
					Percept.new(about: :food_nearby, value: 0) # no food nearby
			end
			(_,_) ->
				nil
		end
	end

  @doc "Heard panic from someone else (and I did not recently say danger)"
  def other_panicking() do
    fn
      (%Percept{about: :heard, value: %{info: %{feeling: :panic}}}, %{intents: intents}) ->
				if not any_memory?(
							intents,
							:say_scared,
							3000,
							fn(_value) -> true end) do
          Logger.warn("@@@@ GROUP PANIC!!! @@@@")
					Percept.new(about: :danger, value: :high)
				else
					nil
				end
	    (_,_) -> nil
      end
  end

  @doc "Heard someone else say food and I did not find food myself"
  def other_eating() do
    fn
      (%Percept{about: :heard, value: %{info: %{doing: :eating}, id_channel: id_channel}}, %{percepts: percepts}) ->
			if not any_memory?(
						percepts,
						:food,
						2000,
						fn(value) -> value in [:litte, :plenty] end) do
        Logger.warn("@@@@ SOMEONE'S at #{id_channel} is EATING!!! @@@@")
        Percept.new(about: :other_eating,
                    value: %{id_channel: id_channel, current: true})
			else
        Percept.new(about: :other_eating,
                    value: %{id_channel: id_channel, current: false})
			end
			(%Percept{about: :time_elapsed}, %{percepts: percepts}) ->
				# For all who have been heard eating but not recently
				old_hearings = select_memories(percepts,
																			 about: :heard,
																			 not_since: 2_000,
																			 test:
				fn(value) ->
					case value do
						%{info: %{doing: :eating}} -> true
						_ -> false
					end
				end)
			new_percepts = Enum.map(old_hearings,
				fn(%Percept{value: %{id_channel: id_channel}}) ->
					Logger.warn("Someone at #{id_channel} is no longer eating")
					Percept.new(about: :other_eating,
											value: %{id_channel: id_channel, current: false})
				end)
			new_percepts
	    (_,_) -> nil
    end
  end

end
