defmodule SmartThing.PerceptionController do

	@moduledoc "SmartThing perception REST API"

  use Phoenix.Controller
	alias Marvin.SmartThing.RESTCommunicator
	alias Marvin.SmartThing.Percept
	require Logger

	@doc "Handle incoming perception from another community"
	def handle_percept(conn,
										 %{"percept" => %{"about" => about_s,
																			"value" => value_s,
																			"source" => %{"community_name" => community_name,
																										"member_name" => member_name,
																										"member_url" => url,
																										"id_channel" => id_channel}
																		 }
											}
			) do
		{about, []} = Code.eval_string(about_s)
		{value, []} = Code.eval_string(value_s)
		percept = Percept.new(about: about,
													value: %{is: value,
																	 from: %{community_name: community_name,
																					 member_name: member_name,
																					 member_url: url,
																					 id_channel: id_channel}
																	},
													source: __MODULE__,
													ttl: 60_000) # reports are always to be remembered for one minute
		RESTCommunicator.remote_percept(percept)
		json(conn, :ok)
	end

end
