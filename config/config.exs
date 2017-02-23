# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config


# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :smart_thing, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:smart_thing, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"


config :marvin,
platforms: %{"mock_rover" => Marvin.MockRover.Platform,
						 "rover" => Marvin.Rover.Platform,
						 "hub" => Marvin.Hub.Platform},
profiles: %{"puppy" => Marvin.Puppy.Profile,
						"mommy" => Marvin.Mommy.Profile},
max_percept_age: 2000,
max_motive_age: 3000,
max_intent_age: 1500,
strong_intent_factor: 3,
max_beacon_channels: 3,
very_fast_rps: 3,
fast_rps: 2,
normal_rps: 1,
slow_rps: 0.5,
very_slow_rps: 0.3

# Configures the endpoint
config :marvin, Marvin.Endpoint,
url: [host: (System.get_env("MARVIN_HOST") || "localhost"),
			port: String.to_integer(System.get_env("MARVIN_PORT") || "4000")],
http: [port: String.to_integer(System.get_env("MARVIN_PORT") || "4000")],
root: Path.dirname(__DIR__),
secret_key_base: "BtqMSrya4yeaCROpSicDZyFSgm+BRcaMaegBORz1SK/oQT811zd4IBnsxg1HLsCn",
render_errors: [accepts: ~w(html json)],
pubsub: [name: Hub.PubSub,
         adapter: Phoenix.PubSub.PG2]

	# Configures Elixir's Logger
# config :logger, :log
# backends: [{LoggerFileBackend, :log}] 

config :logger, :console,
level: :info,
#path: (if (System.get_env("MARVIN_SYSTEM") || "pc") == "ev3", do: "/mnt/rover.log", else: "rover.log"),
format: "$time $metadata[$level] $message\n",
metadata: [:request_id]

import_config "nerves.exs"

# import_config "#{Mix.env}.exs"
