defmodule Marvin.SmartThing.Memory do
	@moduledoc "The memory of percepts"

	use GenServer
	alias Marvin.SmartThing.{Percept, Motive, Intent, CNS}
	import Marvin.SmartThing.Utils
  require Logger

  @name __MODULE__
	@forget_pause 5000 # clear expired precepts every 10 secs
	@motive_ttl 30_000 # superceded motives are forgotten after 30 secs
	@intent_ttl 30_000 # all intents are forgotten after 30 secs

  ### API
	
	@doc "Start the memory server"
	def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	@doc "Remember a percept, motive or intent"
	def store(something) do
		GenServer.cast(@name, {:store, something})
	end

	def store_behavior_stopped(behavior_name) do
		GenServer.cast(@name, {:store_behavior_stopped, behavior_name})
	end

	def store_behavior_transited(behavior_name, to_state_name) do
		GenServer.cast(@name, {:store_behavior_transited, behavior_name, to_state_name})
	end

	@doc "Return percepts memorized since window_width as %{percepts: [...], motives: [...], intents: [...]}"
	def since(window_width, senses: senses, motives: motive_names, intents: intent_names) do
		GenServer.call(@name, {:since, window_width, senses, motive_names, intent_names})
	end

	@doc "Recall all percepts from any of given senses in a time window until now"
	def recall_percepts(senses, window_width) do
		GenServer.call(@name, {:recall_percepts, senses, window_width})
	end

	@doc "Give all currently known motive names"
	def known_motive_names() do
		GenServer.call(@name, :known_motive_names)
	end

	@doc "Recall the history of a named motive, within a time window until now"
	def recall_motives(name, window_width) do
		GenServer.call(@name, {:recall_motives, name, window_width})
	end

	@doc "Whether a motive is inhibited by others"
	def inhibited?(motive_name) do
		GenServer.call(@name, {:inhibited, motive_name})
	end

	@doc "Recall the history of a named intent, within a time window until now"
	def recall_intents(name, window_width) do
		GenServer.call(@name, {:recall_intents, name, window_width})
	end

	@doc "Get all currently on motives"
	def on_motives() do
		GenServer.call(@name, :on_motives)
	end

	@doc "Get the names of all active, non-inhibited behaviors"
	def transited_behavior_names() do
		GenServer.call(@name, :transited_behavior_names)
	end

	### CALLBACKS

	def init(_) do
    pid = spawn_link(fn() -> forget()	end)
		Process.register(pid, :forgetting)
		{:ok, %{percepts: %{}, motives: %{}, intents: %{}, behaviors: %{}}}
	end

	# forget all expired percepts every second
	defp forget() do
			:timer.sleep(@forget_pause)
			send(@name, :forget)
			forget()
	end

	def handle_info(:forget, state) do
		new_state =
			forget_expired_percepts(state)
		|> forget_expired_motives()
		|> forget_expired_intents()
		{:noreply, new_state}
	end

	def handle_cast({:store, %Percept{} = percept}, state) do
    key = Percept.sense(percept)
		percepts = Map.get(state.percepts, key, [])
		new_percepts =  update_percepts(percept, percepts)
		new_state = %{state | percepts: Map.put(state.percepts, key, new_percepts)}
		{:noreply, new_state}
	end

	def handle_cast({:store, %Motive{} = motive}, state) do
		motives = Map.get(state.motives, motive.about, [])
		new_motives = update_motives(motive, motives)
		new_state = %{state | motives: Map.put(state.motives, motive.about, new_motives)}
		{:noreply, new_state}
	end

	def handle_cast({:store, %Intent{} = intent}, state) do
		intents = Map.get(state.intents, intent.about, [])
		new_intents = update_intents(intent, intents)
		new_state = %{state | intents: Map.put(state.intents, intent.about, new_intents)}
		{:noreply, new_state}
	end

	def handle_cast({:store_behavior_stopped, behavior_name}, %{behaviors: behaviors} = state) do
		new_state = %{state | behaviors: behavior_stopped(behaviors, behavior_name)}
		{:noreply, new_state}
	end

	def handle_cast({:store_behavior_transited, behavior_name, to_state_name}, %{behaviors: behaviors} = state) do
		new_state = %{state | behaviors: behavior_transited(behaviors, behavior_name, to_state_name)}
		{:noreply, new_state}
	end

	def handle_call({:recall_percepts, senses, window_width}, _from, state) do
		percepts = recent_percepts(window_width, senses, state)
		{:reply, percepts, state}
	end

	def handle_call({:since, window_width, senses, motive_names, intent_names}, _from, state) do
		percepts = recent_percepts(window_width, senses, state)
		motives = recent_motives(window_width, motive_names, state)
		intents = recent_intents(window_width, intent_names, state)
		{:reply, %{percepts: percepts, motives: motives, intents: intents}, state}
	end


	def handle_call({:inhibited,  motive_name}, _from, state) do
		answer = inhibited_by?(motive_name, state.motives)
		{:reply, answer, state}
	end

	def handle_call(:known_motive_names, _from, state) do
		answer = Enum.filter(Map.keys(state.motives), &(Map.get(state.motives, &1, []) != []))
		{:reply, answer, state}
	end

	def handle_call({:recall_motives, name, window_width}, _from, state) do
		motives = recent_motives(window_width, [name], state)
		{:reply, motives, state}
	end

	def handle_call({:recall_intents, name, window_width}, _from, state) do
	  intents = recent_intents(window_width, [name], state)
		{:reply, intents, state}
	end

	def handle_call(:on_motives, _from, %{motives: motives} = state) do
		on_motives = Enum.reduce(Map.keys(motives),
														 [],
			fn(about, acc) ->
				case Map.fetch!(motives, about) do
					[] ->
						acc
					[motive | _] ->
						if Motive.on?(motive) do
							[motive | acc]
						else
							acc
						end
				end
			end)
		{:reply, on_motives, state}
	end

	def handle_call(:transited_behavior_names, _from, %{behaviors: behaviors} = state) do
		{:reply, Map.keys(behaviors), state}
	end

	### PRIVATE

	defp update_percepts(percept, []) do
		CNS.notify_memorized(:new, percept)
		[percept]
	end

	defp update_percepts(percept, [previous | others]) do
		if not change_felt?(percept, previous) do
			extended_percept = %Percept{previous | until: percept.since}
			CNS.notify_memorized(:extended, extended_percept)
			[extended_percept | others]
		else
			CNS.notify_memorized(:new, percept)
			[percept, previous | others]
		end
	end

	defp update_motives(%Motive{} = motive, []) do
		CNS.notify_memorized(:new, motive)
		[motive]
	end
	
	defp update_motives(%Motive{} = motive, [current|rest]) do
		if not(motive.value == current.value and Map.equal?(motive.details, current.details)) do
			CNS.notify_memorized(:new, motive)
			[motive, current | rest]
		else
			[current|rest]
		end
	end

	defp update_intents(intent, []) do
		CNS.notify_memorized(:new, intent)
		[intent]
	end

	defp update_intents(intent, intents) do
		CNS.notify_memorized(:new, intent)
		[intent | intents]
	end

	
	defp recent_percepts(window_width, senses, state) do
		msecs = now()
		Enum.reduce(
			senses,
			[],
      fn(sense, acc) ->
				percepts = Enum.take_while(
					Map.get(state.percepts, sense, []),
					fn(percept) ->
						window_width == nil or percept.until > (msecs - window_width)
					end)
				acc ++ percepts	
			end)		
	end

	defp recent_motives(window_width, names, state) do
 		msecs = now()
		Enum.reduce(
			names,
			[],
      fn(name, acc) ->
				motives = Enum.take_while(
					Map.get(state.motives, name, []),
					fn(motive) ->
						window_width == nil or motive.since > (msecs - window_width)
					end)
				acc ++ motives	
			end)		
	end

	defp recent_intents(window_width, names, state) do
		msecs = now()
		Enum.reduce(
			names,
			[],
      fn(name, acc) ->
				intents = Enum.take_while(
					Map.get(state.intents, name, []),
					fn(intent) ->
						window_width == nil or intent.since > (msecs - window_width)
					end)
				acc ++ intents	
			end)		
	end

	# Both percepts are assumed to be from the same sense, thus comparable
	defp change_felt?(percept, previous) do
		cond do
			percept.resolution == nil or previous.resolution == nil ->
				percept.value != previous.value
			not is_number(percept.value) or not is_number(previous.value) ->
			  percept.value != previous.value
			true ->
				resolution = max(percept.resolution, previous.resolution)
				abs(percept.value - previous.value) >= resolution
		end
	end

	defp forget_expired_percepts(state) do
		msecs = now()
		remembered = Enum.reduce(
			Map.keys(state.percepts),
														 %{},
			fn(sense, acc) ->
				unexpired = Enum.take_while(
					Map.get(state.percepts, sense),
					fn(percept) ->
						if percept.ttl == nil or (percept.until + percept.ttl) > msecs do
							true
						else
							# Logger.debug("Forgot #{inspect percept.about} = #{inspect percept.value} after #{div(msecs - percept.until, 1000)} secs")
							false
						end
					end)
				Map.put_new(acc, sense, unexpired)
			end)
		%{state | percepts: remembered}
	end

	defp forget_expired_motives(state) do
		msecs = now()
		remembered = Enum.reduce(
			Map.keys(state.motives),
			%{},
			fn(name, acc) ->
				case Map.get(state.motives, name, []) do
					[] -> Map.put_new(acc, name, [])
					[motive] -> Map.put(acc, name, [motive])
					[motive | rest] ->
						expired = Enum.filter(rest, &((&1.since + @motive_ttl) < msecs))
						# Logger.debug("Forgot #{name} motives #{inspect expired}")
						Map.put(acc, name, [motive | rest -- expired])
				end
			end)
		%{state | motives: remembered}
	end

	defp forget_expired_intents(state) do
		msecs = now()
		remembered = Enum.reduce(
			Map.keys(state.intents),
			%{},
			fn(name, acc) ->
				case Map.get(state.intents, name, []) do
					[] -> Map.put_new(acc, name, [])
					intents ->
						expired = Enum.filter(intents, &((&1.since + @intent_ttl) < msecs))
						# Logger.debug("Forgot #{name} intents #{inspect expired}")
						Map.put(acc, name, intents -- expired)
				end
			end)
		%{state | intents: remembered}
	end

	defp inhibited_by?(motive_name, motives) do
		find_on_motives(motives)
		|> any_inhibits?(motive_name)				
	end

	defp any_inhibits?(on_motives, motive_name) do
		any_inhibits?(on_motives, motive_name, [], on_motives)
	end

	defp any_inhibits?([], _motive_name, _inhibitor_names, _on_motives) do
		false
	end

	# a motive can't inhibit itself
	defp any_inhibits?([%Motive{about: motive_name} | rest],  motive_name, inhibitor_names, on_motives) do 
		any_inhibits?(rest, motive_name, inhibitor_names, on_motives)
	end

	defp any_inhibits?([other|rest], motive_name, inhibitor_names, on_motives) do
		if Motive.inhibits_all?(other) or motive_name in other.inhibits do
			other.about in inhibitor_names # deadly embrace
			or not any_inhibits?(on_motives, other.about, [other.about | inhibitor_names], on_motives)
		else
			any_inhibits?(rest, motive_name, inhibitor_names, on_motives)
		end
	end

	defp find_on_motives(motives) do
		Map.keys(motives)
		|> Enum.reduce([],
			fn(key, acc) -> case Map.get(motives, key, []) do
												[] ->
													acc
												[motive | _] ->
													if Motive.on?(motive) do
														[motive | acc]
													else
														acc
													end
											end
			end
		)
	end
	
	defp behavior_transited(behaviors, behavior_name, to_state_name) do
		Map.put(behaviors, behavior_name, to_state_name)
	end

	defp behavior_stopped(behaviors, behavior_name) do
		Map.delete(behaviors, behavior_name)
	end

end
