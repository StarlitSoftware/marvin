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


# Configures the endpoint
config :marvin,
platforms: %{"mock_ev3" => Marvin.Ev3Mock.Platform,
						 "ev3" => Marvin.Ev3.Platform,
						 "hub" => Marvin.Hub.Platform},
profiles: %{"puppy" => Marvin.Puppy.Profile,
						"mommy" => Marvin.Mommy.Profile}

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
config :logger,
level: :info
# backends: if (System.get_env("MARVIN_PLATFORM") || "mock_ev3") == "ev3", do: [{LoggerFileBackend, :log}], else: []

config :logger, :log,
level: :info,
path: (if (System.get_env("MARVIN_PLATFORM") || "mock_ev3") == "ev3", do: "/mnt/ev3.log", else: "ev3.log"),
format: "$time $metadata[$level] $message\n",
metadata: [:request_id]

# if (System.get_env("MARVIN_NERVES") || "no") == "yes", do:
import_config "nerves.exs"

# import_config "#{Mix.env}.exs"
