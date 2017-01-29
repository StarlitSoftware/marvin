defmodule Marvin.SmartThing.Detector do
	@moduledoc "A detector polling a sensor or motor for senses it implements"

	require Logger
  alias Marvin.SmartThing.Percept
	alias Marvin.SmartThing.CNS
  alias Marvin.SmartThing.Device
	alias Marvin.SmartThing

	@ttl 10_000 # detected percept is retained for 10 secs # TODO set in config

	@doc "Start a detector on a sensing device, to be linked to its supervisor"
	def start_link(device, used_senses) do
		name = Device.name(device)
		{:ok, pid} = Agent.start_link(
			fn() ->
				%{device: device, previous_values: %{}}
			end,
			[name: name])
		Logger.info("#{__MODULE__} started on #{inspect device.type} device")
		{:ok, pid}
	end
												 	
	def poll(name, sense) do
		Agent.get_and_update(
			name,
			fn(state) ->
  			{value, updated_device} = read(state.device, sense)
				  if value != nil do
					  percept = if updated_device.mock do
                        previous_value = Map.get(state.previous_values, sense, nil)
                        mocked_value = SmartThing.nudge(updated_device, sense, value, previous_value)
                        Percept.new(about: sense, value: mocked_value)
                      else
                        Percept.new(about: sense, value: value)
                      end
            %Percept{percept |
										 source: name,
										 ttl: @ttl,
										 resolution: sensitivity(updated_device, sense)}
					  |> CNS.notify_perceived()
					  {:ok, %{state |
									  device: updated_device,
                    previous_values: Map.put(state.previous_values, sense, percept.value)}}
				  else
					  {:ok, %{state | device: updated_device}}
				  end
			end)
		:ok
	end

	### Private

	defp read(device, sense) do
		case device.class do
			:sensor -> platform_dispatch(:sensor_read_sense, [device, sense])
			:motor -> platform_dispatch(:motor_read_sense, [device, sense])
		end
	end

	defp sensitivity(device, sense) do
		case device.class do
							 :sensor -> platform_dispatch(:sensor_sensitivity, [device, sense])
							 :motor -> platform_dispatch(:motor_sensitivity, [device, sense])
		end
	end

end
