defmodule Ev3.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "nerves_system_ev3"

   def project() do
    [app: :ev3,
     version: "0.1.0",
     build_path: "../../_build/#{@target}",
     deps_path: "../../deps/#{@target}",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
#     config_path: "../../config/config.exs",
		 archives: [nerves_bootstrap: "~> 0.2"],
		 system: @target,
		 aliases: aliases(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps() ++ system()]
   end

	def application() do
    [applications: [:nerves_interim_wifi, :ex_ncurses, :runtime_tools]]
  end


  def deps() do
    [{:nerves, "~> 0.4", runtime: false},
     {:logger_file_backend, "~> 0.0.8"},
     {:nerves_interim_wifi, "~> 0.0.1"},
     {:ex_ncurses, github: "jfreeze/ex_ncurses", ref: "2fd3ecb1c8a1c5e04ddb496bb8d57f30b619f59e"},
		 {:smart_thing, in_umbrella: true},
		 {:puppy, in_umbrella: true}
		]
  end

  def system() do
    [{:nerves_system_ev3, "~> 0.10.1", runtime: false}]
  end

  def aliases() do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
