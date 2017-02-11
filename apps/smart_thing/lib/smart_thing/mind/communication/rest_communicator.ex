defmodule Marvin.SmartThing.RESTCommunicator do
	@moduledoc "REST communicator used communicate via HTTP with other smart things"

	@behaviour Marvin.SmartThing.Communicating

	alias Marvin.SmartThing.CNS
	alias Marvin.SmartThing
	require Logger
	use GenServer
	
	@name __MODULE__

  def start_link() do
		Logger.info("Starting #{@name}")
		GenServer.start_link(@name, [], [name: @name])
	end

	@doc "Broadcast info to the community"
	def broadcast(_device, _info) do
		Logger.warn("Broadcast not implemented for #{@name}")
	end

	@doc "Send percept to a member of the parent community"
	def send_percept(_device, about, value) do
		GenServer.cast(@name, {:send_percept, about, value})
	end

	def senses_awakened_by(_sense) do
		[]
	end

	def port() do
		SmartThing.rest_source()
	end

	####

	def remote_percept(percept) do
		Logger.info("Received remote percept #{inspect(percept.about)}=#{inspect(percept.value)} from #{inspect(percept.source)}")
		CNS.notify_perceived(percept)
	end
	
	### CALLBACKS

	def init([]) do
		{:ok, []}
	end

	def handle_cast({:send_percept, about, value}, state) do
		url = "http://#{SmartThing.parent_url()}/api/marvin/percept"
		body = %{percept: %{about: "#{inspect about}",
												value: "#{inspect(value)}",
												source: %{community_name: SmartThing.community_name(),
																	member_name: SmartThing.member_name(),
																	url: SmartThing.rest_source()}
											 }
						} |> Poison.encode!()
		headers = [{"Content-Type", "application/json"}]
		Logger.info("Posting to #{url} with #{inspect body}")
		case HTTPoison.post(url, body, headers) do
			{:ok, _response} ->
				Logger.info("Sent percept :report #{inspect value} to #{url}")
			{:error, reason} ->
				Logger.warn("FAILED to send percept #{inspect about} #{inspect value} to #{url} - #{inspect reason}")
		end
		{:noreply, state}
	end

end
