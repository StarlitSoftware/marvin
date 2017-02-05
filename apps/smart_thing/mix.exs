defmodule SmartThing.Mixfile do
  use Mix.Project

 def project() do
    [app: :smart_thing,
     version: "0.1.0",
     deps_path: "../../deps",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
		 elixirc_paths: elixirc_paths(Mix.env),
		 compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application() do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger,
													:logger_file_backend,
													:phoenix,
													:phoenix_html,
													:cowboy,
													:gettext,
													:httpoison
												 ],
     mod: {Marvin.SmartThing.Application, []}
		]
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
    [{:phoenix, "~> 1.1.4"},
     {:phoenix_html, "~> 2.4"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
		 {:httpoison, "~> 0.11"},
     {:poison, "~> 2.0"},
]
  end

end
