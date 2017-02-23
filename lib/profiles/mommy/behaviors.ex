defmodule Marvin.Mommy.Behaviors do
	@moduledoc "Provides the configurations of all mommy behaviors to be activated"

	require Logger
	alias Marvin.SmartThing.{BehaviorConfig, FSM, Transition, Percept}
	import Marvin.SmartThing.BehaviorUtils

	@doc "Give the configurations of all behaviors to be activated by motives and driven by percepts"
  def behavior_configs() do
		[
			BehaviorConfig.new( # parenting
				name: :parenting,
				motivated_by: [:maternal_instinct],
				senses: [:out_of_control_panicking, :food_hogging],
				fsm: %FSM{
					initial_state: :started,
					final_state: :ended,
					transitions: [
						%Transition{to: :started,
												doing: start_parenting()},																 
						%Transition{from: [:started],
												on: :out_of_control_panicking,
												to: :started,
												doing: calm_down_brood()
											 },
						%Transition{from: [:started],
												on: :food_hogging,
												to: :started,
												doing: stop_food_hogging()
											 },
						%Transition{to: :ended,
												doing: nothing()}
					]
				}
			)
		]
	end

	def calm_down_brood() do
		fn(%Percept{about: :out_of_control_panicking,
								 value: %{member_name: member_name, member_url: url}}, _state) ->
			Logger.info("COMMAND TO CALM DOWN")
			generate_intent(:say_calm_down, %{member_name: member_name})
			generate_intent(:command, %{command: :calm_down,
																	to_url:  url})
		end
	end

	def start_parenting() do
		fn(_percept, _state) ->
			Logger.info("STARTING PARENTING")
			generate_intent(:say_parenting)
		end
	end

	def stop_food_hogging() do
		fn(%Percept{about: :food_hogging, value: %{member_name: member_name, member_url: url}}, _state) ->
			Logger.info("COMMAND TO STOP EATING")
			generate_intent(:say_share_food, %{member_name: member_name})
			generate_intent(:command, %{command: :stop_eating,
																	to_url:  url})
		end
	end

end
