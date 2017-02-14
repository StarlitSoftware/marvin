defmodule Marvin.Puppy.Motivation do
	@moduledoc "Provides the configurations of all motivators to be activated"

	require Logger

	alias Marvin.SmartThing.{MotivatorConfig, Motive, Percept}
	import Marvin.SmartThing.MemoryUtils
	
	@doc "Give the configurations of all motivators. Motivators turn motives on and off"
  def motivator_configs() do
		[
			# A curiosity motivator
			MotivatorConfig.new(
				name: :curiosity,
				focus: %{senses: [:time_elapsed], motives: [], intents: []},
				span: nil,
				logic: curiosity()
			),
			# A hunger motivator
			MotivatorConfig.new(
				name: :hunger,
				focus: %{senses: [:hungry, :danger, :mom_says], motives: [], intents: []},
				span: nil, # for as long as we can remember
				logic: hunger(),
			),
			# A fear motivator
			MotivatorConfig.new(
				name: :fear,
				focus: %{senses: [:danger, :mom_says], motives: [], intents: []},
				span: nil, # for as long as we can remember
				logic: fear()
			),
      # Tracking another robot to steal its food
      MotivatorConfig.new(
        name: :greed,
        focus: %{senses: [:other_eating], motives: [:hunger], intents: []},
        span: nil,
        logic: greed()
      )
		]
	end

  @doc "Find all senses used for motivation"
  def used_senses() do
    motivator_configs()
    |> Enum.map(&(Map.get(&1.focus, :senses, [])))
    |> List.flatten()
    |> MapSet.new()
    |> MapSet.to_list()
  end

	@doc "Curiosity motivation"
	def curiosity() do
		fn
		(%Percept{about: :time_elapsed}, _) ->
				Motive.on(:curiosity) # never turned off
		end
	end
	
	@doc "Hunger motivation"
	def hunger() do
		fn
		(%Percept{about: :hungry, value: :very}, %{percepts: percepts }) ->
			no_danger? = not any_memory?(percepts, :danger, 5_000, fn(_value) -> true end)
			mom_allows? = not any_memory?(percepts,
																	 :mom_says,
																	 5_000,
				fn(value) ->
					case value do
						%{is: %{command: :stop_eating}} ->
							true
						_ ->
							false
					end
					end)
			if no_danger? && mom_allows? do
					Motive.on(:hunger) |> Motive.inhibit(:curiosity)
				else
					Motive.off(:hunger)
			end
			(%Percept{about: :mom_says, value: %{is: %{command: :stop_eating}}}, _) ->
				Motive.off(:hunger)
	  (%Percept{about: :hungry, value: :not}, _) ->
				Motive.off(:hunger)
	  (_,_) ->
				nil
		end
	end

	@doc "Fear motivation"
	def fear() do
		fn
		(%Percept{about: :danger, value: :high}, _) ->
				Motive.on(:fear) |> Motive.inhibit_all()
		(%Percept{about: :mom_says, value: %{is: %{command: :calm_down}}}, _) ->
				Motive.off(:fear)
		(%Percept{about: :danger, value: :none}, _) ->
				Motive.off(:fear)
		(_,_) ->
				nil
		end
	end

  @doc "Motivation to compete for food"
  def greed() do
    fn
      (%Percept{about: :other_eating, value: %{current: true, id_channel: id_channel}}, %{motives: motives}) ->
      if latest_memory?(
            motives,
            :hunger,
            fn(value) -> value == :on end) do
				Logger.warn("GREED toward #{id_channel} IS ON")
        Motive.on(:greed, %{id_channel: id_channel}) |> Motive.inhibit(:hunger)
	    else
        nil
      end
      (%Percept{about: :other_eating, value: %{current: false, id_channel: id_channel}}, _) ->
				Logger.warn("GREED toward #{id_channel} IS OFF")
        Motive.off(:greed, %{id_channel: id_channel})
		  (_,_) ->
				nil
    end
	end
  
end

