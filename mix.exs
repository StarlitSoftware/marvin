defmodule SmartThing.Mixfile do
  use Mix.Project

 @target System.get_env("NERVES_TARGET") || "nerves_system_ev3"
	
 def project() do
    [app: :marvin,
     version: "0.1.0",
     deps_path: "deps",
     build_path: "_build",
     archives: [nerves_bootstrap: "~> 0.2"],
		 system: @target,
     elixir: "~> 1.4",
		 elixirc_paths: elixirc_paths(Mix.env),
		 compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps() ++ system()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application() do
    # Specify extra applications you'll use from Erlang/Elixir
    [applications: [:runtime_tools, 
													:logger,
													:logger_file_backend,
													:phoenix,  
													:phoenix_html,
													:cowboy,
													:gettext,
													:httpoison,
													:elixir_make
												 ] ++ nerves_apps(),
    mod: {Marvin.Application, []} 
		]
  end

 defp nerves_apps() do
		 [:nerves_interim_wifi,
			:ex_ncurses]
 end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

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
    [
#		 {:phoenix, "~> 1.1.4"},
     {:phoenix_html, "~> 2.4"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
		 {:httpoison, "~> 0.11"},
     {:poison, "~> 2.0"},
		 {:nerves, "~> 0.4", runtime: false},
     {:logger_file_backend, "~> 0.0.8"},
     {:nerves_interim_wifi, "~> 0.0.1"},
     {:ex_ncurses, github: "jfreeze/ex_ncurses", ref: "2fd3ecb1c8a1c5e04ddb496bb8d57f30b619f59e"}
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
