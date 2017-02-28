defmodule Marvin.Mommy.Perception do
	@moduledoc "Mommy's perception"

	import Marvin.SmartThing.MemoryUtils
	require Logger
	alias Marvin.SmartThing.{PerceptorConfig, Percept}

	def perceptor_configs() do
		[
			# The brood is panicking out of control
			PerceptorConfig.new(
				name: :out_control_panicking,
				generates: [:out_of_control_panicking],
				focus: %{senses: [:report], motives: [], intents: []},
				span: {30, :secs},
				ttl: {30, :secs},
				logic: out_of_control_panicking()),
			# A pup is hogging food from a hungry sibling
			PerceptorConfig.new(
				name: :food_hogging,
				generates: [:food_hogging],
				focus: %{senses: [:report], motives: [], intents: []},
				span: {30, :secs},
				ttl: {30, :secs},
				logic: food_hogging())
		]
	end

	@doc "Is the brood panicking out of control?"
	def out_of_control_panicking() do
		fn
			(%Percept{about: :report,
								value: %{is: %{feeling: :panic}},
							 },
				%{percepts: percepts}) ->
				recent_panics = select_memories(
				percepts,
				about: :report,
				since: 10_000,
				test: fn(%{is: reported}) -> Map.equal?(reported, %{feeling: :panic}) end)
		if Enum.count(recent_panics) > 1 do
			uniques = Enum.uniq_by(recent_panics, fn(%Percept{value: %{from: from}}) -> from end)
			Enum.map(uniques,
				fn(%Percept{value: %{from: from}}) ->
					Percept.new(about:
											:out_of_control_panicking,
											value: %{member_name: from.member_name, member_url: from.member_url})
				end)
		else
			nil
		end
			(_, _) ->
				nil
		end
	end

	@doc "A pup is hogging the food from a hungry sibling"
	def food_hogging() do
		fn
			(%Percept{about: :report,
								value: %{is: %{feeling: :food_nearby,
															 channel: channel},
												 from: %{community_name: community,
																 member_url: puppy_url}}},
				%{percepts: percepts}) when channel != 0 ->
				hoggings = select_memories(percepts,
																	 about: :report,
																	 since: 30_000,
				test: fn(value) ->
					case value do
						%{is: %{doing: :eating},
							from: %{community_name: a_community,
											member_url: other_puppy_url,
											 id_channel: a_channel}} when channel == a_channel and community == a_community and puppy_url != other_puppy_url ->
							true
						_ ->
							false
					end
				end)
			if Enum.count(hoggings) != 0 do
				[%Percept{value: %{from: %{member_url: hogger_url, member_name: hogger_name}}} | _ ] = hoggings
				Percept.new(about: :food_hogging,
										value: %{member_url: hogger_url,
														 member_name: hogger_name})
			else
				nil
			end
			(_,_) -> nil
		end
	end

end
