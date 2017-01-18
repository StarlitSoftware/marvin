defmodule Ev3.Mixfile do
  use Mix.Project

  def project do
    [app: :ev3,
     version: "0.1.0",
     config_path: "../../config/config.exs",
     lockfile: "../../mix.lock",
     
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def deps do
    []
  end

end
