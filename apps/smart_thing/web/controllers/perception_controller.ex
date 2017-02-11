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
																													 "url" => url}
																		 }
											} = params
			) do
		{about, []} = Code.eval_string(about_s)
		{value, []} = Code.eval_string(value_s)
		percept = Percept.new(about: about,
													value: value,
													source: %{community_name: community_name,
																		member_name: member_name,
																		url: url}
		)
		RESTCommunicator.remote_percept(percept)
		json(conn, :ok)
	end

end
