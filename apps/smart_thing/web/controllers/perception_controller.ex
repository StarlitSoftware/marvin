defmodule Marvin.SmartThing.PerceptionController do

	@moduledoc "SmartThing perception REST API"

  use Phoenix.Controller
	alias Marvin.SmartThing.RESTCommunicator
	alias Marvin.SmartThing.Percept

	@doc "Handle incoming perception from another community"
	def handle_percept(conn,  %{"percept" => %{"about" => about,
																						 "value" => value,
																						 "source" => %{"community_name" => community_name,
																													 "member_name" => member_name,
																													 "rest_host" => rest_host}
																						}
														 }) do
		percept = Percept.new(about: about,
													value: value,
													source: %{community_name: community_name,
																		member_name: member_name,
																		rest_host: rest_host}
		)
		RESTCommunicator.remote_percept(percept)
		json(conn, :ok)
	end

end
