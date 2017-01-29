defmodule Marvin.SmartThing.Behavior do
	@moduledoc "A behavior triggered by and meant to satisfy a motive"

	alias Marvin.SmartThing.{Memory, Percept, Motive, Transition, FSM, BehaviorConfig, CNS}
	require Logger

	@max_percept_age 1000 # 1000 # percepts older than 1 sec are stale
	@max_motive_age 3000 # 3000 # motives older than 3 secs are stale

	@doc "Start a behavior from a configuration"
	def start_link(behavior_config) do
		Logger.info("Starting #{__MODULE__} #{behavior_config.name}")
		Agent.start_link(fn() -> %{name: behavior_config.name,
                               reflex: BehaviorConfig.reflex?(behavior_config),
															 fsm: behavior_config.fsm,
															 motives: [],
															 fsm_state: nil } end,
										 [name: behavior_config.name])
	end

	@doc "A named behavior responds to a motive by starting or stopping the fsm, if responsive"
	def react_to_motive(name, %Motive{} = motive) do
		Agent.update(
			name,
			fn(state) ->
        if check_freshness(name, motive) do
				  if Motive.on?(motive) do
					  start(motive, state) # if applicable
				  else
					  stop(motive, state) # if applicable
				  end
        else
          state
        end
			end,
      10000 # 5000 is sometimes not enough
    )
	end

  @doc "A named behavior responds to a percept if responsive"
	def react_to_percept(name, %Percept{} = percept) do
		Agent.update(
			name,
			fn(state) ->
        if check_freshness(name, percept) do
				  case transit_on(percept, state) do
					  %{reflex: reflex,
							fsm_state: final_state,
							fsm: %FSM{final_state: final_state}
						 } = end_state when not reflex ->
						  final_transit(end_state)
					  new_state ->
						  new_state
				  end
        else
          state
        end
			end,
      10000
		)
	end

 	### Private

	defp inhibited?(%{motives: motives} = _state) do
		Enum.all?(motives, &Memory.inhibited?(&1.about))
	end

	defp start(on_motive,  %{fsm_state: nil} = state) do # might start only if not started yet
		if not Memory.inhibited?(on_motive.about) do
			if not on_motive in state.motives do
				Logger.info("STARTED behavior #{state.name}")
        CNS.notify_started(:behavior, state.name, state.reflex)
				initial_transit(%{state | motives: [on_motive | state.motives]})
			else
				state
			end
		else
			state
		end
	end

	defp start(_on_motive, state) do # don't start if already started
		state
	end

	defp stop(_off_motive, %{fsm_state: nil} = state) do # already stopped, do nothing
		state
	end
	
	defp stop(off_motive, state) do # might stop or do nothing
		surviving_motives = Enum.filter(state.motives, &(&1.about != off_motive.about))
		case surviving_motives do
			[] ->
				Logger.info("STOPPED behavior #{state.name}: #{off_motive.about} if off")
				final_transit(state)
        CNS.notify_stopped(:behavior, state.name, state.reflex)
				%{state | motives: [], fsm_state: nil}
			motives ->
				Logger.info("NOT STOPPED behavior #{state.name} because #{inspect surviving_motives}")
				%{state | motives: motives}
		end
	end

	defp initial_transit(%{fsm_state: nil, fsm: fsm} = state) do
		transition = find_initial_transition(fsm)
		if transition != nil do
      CNS.notify_transited(:behavior, state.name, transition.to)
			transition.doing.(nil, state)
		end
		%{state | fsm_state: fsm.initial_state}
	end

	defp final_transit(%{fsm: fsm} = state) do
		transition = find_final_transition(fsm)
		if transition != nil do
      CNS.notify_transited(:behavior, state.name, transition.to)
			transition.doing.(nil, state)
		end
		%{state | fsm_state: nil}
	end

	defp find_initial_transition(%FSM{initial_state: initial_state,
																		transitions: transitions}) do
		Enum.find(transitions,
							&(&1.from == nil and &1.to == initial_state and &1.doing != nil)
		)
	end

	defp find_final_transition(%FSM{final_state: final_state, transitions: transitions}) do
		Enum.find(transitions,
							&(&1.to == final_state and &1.doing != nil)
		)
	end

	defp transit_on(_percept, %{fsm_state: nil, reflex: false} = state) do # do nothing if not started
		state
	end

  defp transit_on(percept, %{reflex: true} = state) do
    case find_transition(percept, state) do
      nil ->
        CNS.notify_stopped(:behavior, state.name, true)
        state
      %Transition{doing: action} ->
        CNS.notify_reflexed(:behavior, state.name, {percept.about, percept.value})
        action.(percept, state)
        state
    end
  end
	
	defp transit_on(percept, state) do
		case find_transition(percept, state) do
			nil ->
				state
			transition ->
				if not inhibited?(state) do
            CNS.notify_transited(:behavior, state.name, transition.to)
						apply_transition(transition, percept, state)
				else
					Logger.info("-- INHIBITED: behavior #{state.name}")
          CNS.notify_inhibited(:behavior, state.name)
					state
				end
		end
	end

  defp find_transition(percept, %{fsm: fsm, reflex: true, motives: motives}) do
    fsm.transitions
		|> Enum.find(fn(transition) ->
      Percept.sense(percept) == transition.on # TODO account for qualified percept abouts
      and transition.condition == nil or transition.condition.(percept.value, motives)
    end)
  end

	defp find_transition(percept, %{fsm_state: fsm_state, fsm: fsm, motives: motives} = _state) do
		fsm.transitions
		|> Enum.find(fn(transition) ->
			transition.from != nil # else initial transition
			and fsm_state in transition.from
			and Percept.sense(percept) == transition.on # TODO account for qualified percept abouts
			and (transition.condition == nil or transition.condition.(percept.value, motives))
		end)
	end

	defp apply_transition(%Transition{doing: nil} = transition, _percept, state) do
		%{state | fsm_state: transition.to}
	end

	defp apply_transition(%Transition{doing: action} = transition, percept, state) do
		action.(percept, state)
		%{state | fsm_state: transition.to}
	end

  defp check_freshness(name, %Percept{} = percept) do
    age = Percept.age(percept)
    if age > @max_percept_age do
      Logger.info("STALE percept #{inspect percept.about} #{age}")
      CNS.notify_overwhelmed(:behavior, name)
      false
    else
      true
    end
  end

  defp check_freshness(name, %Motive{} = motive) do
    age = Motive.age(motive)
    if 	age > @max_motive_age do
      Logger.warn("STALE motive #{inspect motive.about} #{age}")
      CNS.notify_overwhelmed(:behavior, name)
      false
    else
      true
    end
  end

end
