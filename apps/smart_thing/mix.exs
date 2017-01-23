defmodule SmartThing.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "ev3"

  def project() do
    [app: :smart_thing,
     version: "0.1.0",
       target: @target,
     archives: [nerves_bootstrap: "~> 0.2.1"],     
     deps_path: "../../deps/#{@target}",
     build_path: "../../_build/#{@target}",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps() ++ system(@target)]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application() do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :logger_file_backend, :gen_stage, :nerves_interim_wifi, :ex_ncurses],
     mod: {Marvin.SmartThing.Application, []}
		]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps() do
    [{:gen_stage, "~> 0.10"},
		 {:nerves, "~> 0.4.0"},
#		 {:nerves_networking, github: "nerves-project/nerves_networking"},
     {:logger_file_backend, "~> 0.0.9"},
#     {:nerves_interim_wifi, "~> 0.1.0"},
		 {:ex_ncurses, github: "fhunleth/ex_ncurses", branch: "bump_deps"}
		]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application() do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Marvin.SmartThing.Application, []}]
  end

  def system(target) do
    [{:"nerves_system_#{target}", ">= 0.0.0"}]
  end

  def aliases() do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
