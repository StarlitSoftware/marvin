defmodule Marvin.Puppy.Behaviors do
	@moduledoc "Provides the configurations of all puppy behaviors to be activated"

	require Logger
	import Marvin.SmartThing.BehaviorUtils
	alias Marvin.SmartThing.{BehaviorConfig, FSM, Transition, Percept}

	@doc "Give the configurations of all behaviors to be activated by motives and driven by percepts"
  def behavior_configs() do
		[
      # Reflexive behaviors
      
      BehaviorConfig.new( # Collision avoidance reflex
        name: :colliding, # no motivation, start or final state -> it's a reflex
      senses: [:collision],
      fsm: %FSM{
        transitions: [
					%Transition{on: :collision,
											 condition: fn(value, _sense_qualifier, _motives) -> value == :imminent end,
										 doing: avoid_collision()
										 },
   				%Transition{on: :collision,
											 condition: fn(value, _sense_qualifier, _motives) -> value == :now end,
										 doing: backoff(true)
										 }
        ]
      }
      ),
      BehaviorConfig.new( # Getting unstuck
        name: :getting_unstuck,
        senses: [:stuck],
        fsm: %FSM{
          transitions: [
						%Transition{on: :stuck,
                         condition: fn(value, _sense_qualifier, _motives) -> value end, # true or false
											 doing: unstuck()
											 }
          ]
        }
      ),
      BehaviorConfig.new( # Reacting to communications from community members
        name: :confirming_heard,
        senses: [:heard],
        fsm: %FSM{
          transitions: [
						%Transition{on: :heard,
												doing: confirming_heard()
											 }
          ]
        }
      ),
      
      # Motivated behaviors
      
			BehaviorConfig.new( # roam around
				name: :exploring,
				motivated_by: [:curiosity],
				senses: [:collision, :time_elapsed],
				fsm: %FSM{
					initial_state: :started,
					final_state: :ended,
					transitions: [
						%Transition{to: :started,
												doing: start_roaming()},																 
						%Transition{from: [:started],
												on: :time_elapsed,
												to: :roaming,
												doing: nil
											 },
						%Transition{from: [:roaming],
												on: :time_elapsed,
												to: :roaming,
												doing: roam()
											 },
						%Transition{to: :ended,
												doing: nothing()}
					]
				}
			),
      
			BehaviorConfig.new( # look for food in bright places
				name: :foraging,
				motivated_by: [:hunger],
				senses: [:food, :scent_strength, :scent_direction],
				fsm: %FSM{
					initial_state: :started,
					final_state: :ended,
					transitions: [
						%Transition{to: :started,
												doing: start_foraging() },																 
						%Transition{from: [:started, :on_scent],
												on: :scent_strength,
												to: :on_scent,
												doing: stay_the_course() # faster or slower according to closer or farther
											 },
						%Transition{from: [:off_scent],
												on: :scent_direction,
												to: :on_scent,
												 condition: fn({orientation, _value, _strength, channel}, _sense_qualifier, _motives) ->
                           channel == 1 and orientation == :ahead end
											 },
						%Transition{from: [:on_scent, :off_scent],
												on: :scent_direction,
												to: :off_scent,
												 condition: fn({orientation, _value, _strength, channel}, _sense_qualifier, _motives) ->
                           channel == 1 and
                           orientation != :ahead end,
											 doing: change_course()
											 },
						%Transition{from: [:on_scent, :off_scent],
												on: :scent_strength,
												to: :off_scent,
												 condition: fn({value, channel}, _sense_qualifier, _motives) ->
                           channel == 1 and value == :unknown end,
											 doing: change_course()
											 },
						%Transition{from: [:on_scent, :off_scent, :feeding],
												on: :food,
												 condition: fn(value, _sense_qualifier, _motives) -> value != :none end,
											 to: :feeding,
											 doing: eat()
											 },
						%Transition{from: [:feeding],
												on: :food,
												 condition: fn(value, _sense_qualifier, _motives) -> value == :none end,
											 to: :off_scent,
											 doing: backoff(false)
											 },
						%Transition{to: :ended,
												doing: turn_on_green_leds()
											 }
					]
				}
			),

			BehaviorConfig.new( # Track another community member to compete for a food source
				name: :tracking,
				motivated_by: [:greed],
				senses: [:food, :food_nearby, :scent_strength, :scent_direction],
				fsm: %FSM{
					initial_state: :started,
					final_state: :ended,
					transitions: [
						%Transition{to: :started,
												doing: start_tracking() },																 
						%Transition{from: [:started, :on_track],
												on: :scent_strength,
												to: :on_track,
												doing: stay_the_course() # faster or slower according to closer or farther
											 },
						%Transition{from: [:off_track],
												on: :scent_direction,
												to: :on_track,
												 condition: fn({orientation, _value, _former_strength, channel}, _sense_qualifier, motives) ->
                           case find_motive(motives, :greed) do
                             nil -> false
                             motive -> Map.get(motive.details, :id_channel) == channel
                               and orientation == :ahead
                           end
                         end
											 },
						%Transition{from: [:on_track, :off_track],
												on: :scent_direction,
												to: :off_track,
												 condition: fn({orientation, _value, _former_strength, channel}, _sense_qualifier, motives) ->
                           case find_motive(motives, :greed) do
                             nil -> false
                             motive -> Map.get(motive.details, :id_channel) == channel
                               and orientation != :ahead
                           end
                         end,
											   doing: change_course()
											 },
						%Transition{from: [:on_track, :off_track],
												on: :scent_strength,
												to: :off_scent,
												 condition: fn({value, channel}, _sense_qualifier, motives) ->
                           case find_motive(motives, :greed) do
                             nil -> false
                             motive -> Map.get(motive.details, :id_channel) == channel
                               and value == :unknown
                           end
                         end,
											   doing: change_course()
											 },
						%Transition{from: [:on_track, :off_track],
												on: :food_nearby,
												to: :on_track,
												 condition: fn(value, _sense_qualifier, _motives) ->
                           value != 0 # channel 0 means no food nearby
                         end,
											   doing: express_food_nearby()
											 },
						%Transition{to: :ended,
												doing: stop_tracking()
											 }
					]
				}
			),
     
			BehaviorConfig.new( # now is the time to panic!
				name: :panicking,
				motivated_by: [:fear],
				senses: [:light, :time_elapsed],
				fsm: %FSM{
					initial_state: :started,
					final_state: :ended,
					transitions: [
						%Transition{to: :started,
												doing: start_panicking()},																 
						%Transition{from: [:started, :panicking],
												on: :time_elapsed,
												to: :panicking,
												doing: panic()},
						%Transition{from: [:panicking],
												on: :danger,
												to: :ended,
												 condition: fn(value, _sense_qualifier, _motives) -> value == :none end,
											 doing: nil},
						%Transition{to: :ended,
												doing: calm_down()
											 }

					]
				}
			) 
		] 
	end

  @doc "Find all senses used for behaviors"
  def used_senses() do
    behavior_configs()
    |> Enum.map(&(Map.get(&1, :senses, [])))
    |> List.flatten()
    |> MapSet.new()
    |> MapSet.to_list()
  end
	
  ### Private

	defp turn_on_green_leds() do
		fn(_percept, _state) ->
			green_lights()
		end
	end

	defp turn_on_red_leds() do
		fn(_percept, _state) ->
			red_lights()
		end
	end

  defp start_roaming() do
		fn(_percept, _state) ->
			Logger.info("START ROAMING")
      green_lights()
			generate_intent(:broadcast, %{doing: :roaming})
			generate_intent(:report, %{doing: :roaming})
      generate_intent(:say_curious)
    end
  end

	defp roam() do
		fn(percept, _state) ->
			Logger.info("ROAMING from #{percept.about} = #{inspect percept.value}")
			green_lights()
			if :rand.uniform(2) == 1 do
				turn_where = case :rand.uniform(2) do
											 1 -> :turn_left
											 2 -> :turn_right
										 end
        generate_intent(turn_where, :rand.uniform(10))
			end
      generate_intent(:go_forward,  %{speed: :normal, time: 1})
		end
	end

	defp avoid_collision() do
		fn(percept, _state) ->
			Logger.info("AVOIDING COLLISION from #{percept.about} = #{inspect percept.value}")
      generate_intent(:say_uh_oh)
			turn_where = case :rand.uniform(2) do
										 1 -> :turn_left
										 2 -> :turn_right
									 end
      generate_intent(turn_where, 4)
		end
	end

  defp unstuck() do
    fn(_percept, _state) ->
      Logger.info("GETTING UNSTUCK")
      generate_intent(:say_stuck)
      intend_backoff(true)
    end
  end

  defp intend_backoff(strong?) do
		how_long = 10 + :rand.uniform(6) # secs
    generate_intent(:go_backward,  %{speed: :slow, time: how_long}, strong?)
		turn_where = case :rand.uniform(2) do
									 1 -> :turn_left
									 2 -> :turn_right
								 end
		generate_intent(turn_where, :rand.uniform(5) + 4, strong?)
  end    


	defp backoff(strong?) do
		fn(percept, _state) ->
			Logger.info("BACKING OFF from #{percept.about} = #{inspect percept.value}")
      intend_backoff(strong?)
		end 
	end

	defp stay_the_course() do
		fn(%Percept{about: :scent_strength, value: {value, _channel}} = percept, _state) ->
			Logger.info("STAYING THE COURSE from #{percept.about} = #{inspect percept.value}")
			speed = case value do
								:unknown-> :very_fast
								:very_weak -> :very_fast
								:weak -> :fast
								:strong -> :slow
							  :very_strong -> :very_slow
							end
			generate_intent(:go_forward, %{speed: speed, time: 1})
		end 
	end

	defp change_course() do
		fn
			(%Percept{about: :scent_direction, value: {orientation, value, strength, _channel}} = percept, _state) ->
			  Logger.info("CHANGING COURSE from #{percept.about} = #{inspect percept.value}")
      factor = case strength do
                 nil -> 1
                 :very_strong -> 1.5
                 :strong -> 1.2
                 :weak -> 1
                 :very_weak -> 1
                 :unknown -> 1
               end
			{turn_where, how_much} = case orientation do
																 :left -> {:turn_left, factor * value / 60}
																 :right -> {:turn_right, factor * value / 60}
																 :ahead -> {:turn_right, 0}
															 end
			generate_intent(turn_where, how_much)
			
			(%Percept{about: :scent_strength, value: _value} = percept, _state) ->
				Logger.info("CHANGING COURSE from #{percept.about} = #{inspect percept.value}")
			turn_where = case :rand.uniform(2) do
										 1 -> :turn_left
										 2 -> :turn_right
									 end
			how_much = round(:rand.uniform(5) / 3)
			generate_intent(turn_where, how_much)
		end
	end

  defp start_foraging() do
		fn(_percept, _state) ->
      Logger.info("START FORAGING")
      green_lights()
      generate_intent(:say_hungry)
			generate_intent(:broadcast, %{doing: :foraging})
			generate_intent(:report, %{doing: :foraging})
    end
  end

   defp start_tracking() do
		fn(_percept, _state) ->
      Logger.info("START TRACKING")
      green_lights()
      generate_intent(:say_tracking)
			generate_intent(:broadcast, %{doing: :tracking})
			generate_intent(:report, %{doing: :tracking})
    end
   end

  defp stop_tracking() do
		fn(_percept, _state) ->
			Logger.info("STOP TRACKING")
			turn_on_green_leds()
			generate_intent(:report, %{stopping: :tracking})
		end
	end
 
	defp eat() do
		fn(%Percept{about: :food, value: value}, _state) ->
			Logger.info("EATING from food = #{inspect value}")
			orange_lights()
			generate_intent(:stop, nil, true)
			how_much = case value do
									 :plenty -> :lots
									 :little -> :some
								 end
      generate_intent(:eating_noises)
			generate_intent(:broadcast, %{doing: :eating})
			generate_intent(:report, %{doing: :eating})
			generate_intent(:eat, how_much)
		end
	end

	defp express_food_nearby() do
		fn(%Percept{about: :food_nearby, value: channel}, _state) ->
			Logger.info("EXPRESSING food nearby (channel = #{channel})")
			generate_intent(:say_food_nearby)
			generate_intent(:broadcast, %{feeling: :food_nearby})
			generate_intent(:report, %{feeling: :food_nearby,
																 channel: channel})
		end
	end

  defp start_panicking() do
    fn(_percept, _state) ->
      red_lights()
			Logger.info("PANICKING")
      generate_intent(:say_scared)
 			generate_intent(:broadcast, %{feeling: :panic})
 			generate_intent(:report, %{feeling: :panic})
		end
  end
	
	defp panic() do
		fn(_percept, _state) ->
			red_lights()
      for _n <- 1 .. :rand.uniform(4) do
			  generate_intent(:go_backward, %{speed: :fast, time: 1}, true)
			  turn_where = case :rand.uniform(2) do
											 1 -> :turn_left
											 2 -> :turn_right
										 end
		    generate_intent(turn_where, :rand.uniform(5) + 2, true)
      end
		end
	end

	defp confirming_heard() do
		fn(%Percept{about: :heard, value: %{info: info}}, _state) ->
			words = case info do
								map when is_map(map) ->
									map_to_phrase(map)
								string when is_binary(string) ->
									string
							end
			generate_intent(:say, "I heard #{words}")
		end
	end

	def map_to_phrase(map) when is_map(map) do
		Enum.reduce(map,
								"",
			fn({key, value}, acc) ->
				"#{key} #{value} #{acc}"
			end)
	end		
	
	def calm_down() do
		fn(_percept, _state) ->
			Logger.info("CALMING DOWN")
			green_lights()
		end
	end

	defp red_lights() do
		Logger.info("TURNING ON RED LIGHTS")
		generate_intent(:red_lights, :on, true)
	end
	

	defp green_lights() do
		Logger.info("TURNING ON GREEN LIGHTS")
		generate_intent(:green_lights, :on, true)
	end

	defp orange_lights() do
		Logger.info("TURNING ON ORANGE LIGHTS")
		generate_intent(:orange_lights, :on, true)
	end

  defp find_motive(motives, about) do
    Enum.find(motives, &(&1.about == about))
  end

end
