defmodule Marvin.Application do
	@moduledoc "The smart thing command and control application"
	
  use Application
  require Logger
	alias Marvin.SmartThing.{SmartThingSupervisor, CNS, InternalClock}
	alias Marvin.SmartThing
  import Supervisor.Spec, warn: false

  @poll_runtime_delay 5000
	@max_waits 20
	
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
		Logger.info("Starting #{__MODULE__}")
		Marvin.SmartThing.start_platform()
		wait_for_platform_ready(0)
    children = [
			supervisor(Marvin.Endpoint, []),
			supervisor(SmartThingSupervisor, [])
    ]
    opts = [strategy: :one_for_one, name: :root_supervisor]
    result = Supervisor.start_link(children, opts)
		go()
		result
  end

  @doc "Return ERTS runtime stats"
  def runtime_stats() do  # In camelCase for Elm's automatic translation
    stats = mem_stats(SmartThing.system())
    %{ramFree: stats.mem_free,
      ramUsed:  stats.mem_used,
      swapFree: stats.swap_free,
      swapUsed: stats.swap_used}
  end

  @doc "Loop pushing runtime stats every @poll_runtime_delay seconds"
  def push_runtime_stats() do
    CNS.notify_runtime_stats(runtime_stats())
    :timer.sleep(@poll_runtime_delay)
    push_runtime_stats()
  end

	@doc "Shut down the SmartThing"
	def shutdown() do
		CNS.notify_shutdown()
	end

	def toggle_paused() do
		CNS.toggle_paused()
	end

	def go() do
	  spawn_link(fn() -> connect_to_nodes() end)
		SmartThingSupervisor.start_execution()
		SmartThingSupervisor.start_perception()
    Process.spawn(fn -> push_runtime_stats() end, [])
		InternalClock.resume()
	end

  ### Private


	defp wait_for_platform_ready(n) do
		if SmartThing.platform_ready?() do
			Process.sleep(1000) # TODO - necessary?
			Logger.info("Platform ready!")
			:ok
		else
			if n >= @max_waits do
				{:error, :platform_not_ready}
			else
				Logger.info("Platform not ready")
				Process.sleep(1_000)
				wait_for_platform_ready(n + 1)
			end
		end
	end

	defp connect_to_nodes() do
		Node.connect(Marvin.SmartThing.peer()) # try to join the peer network
		if Node.list() == [] do
			Process.sleep(1_000)
			connect_to_nodes() # try again
		else
			Logger.info("#{Node.self()} is connected to #{inspect Node.list()}")
		end
	end

  defp mem_stats("ev3") do
    {res, 0} = System.cmd("free", ["-m"])
    [_labels, mem, _buffers, swap | _] = String.split(res, "\n")
    [_, _mem_total, mem_used, mem_free, _, _, _] = String.split(mem) 
	  [_, _swap_total, swap_used, swap_free] = String.split(swap)
    %{mem_free: to_int!(mem_free),
      mem_used: to_int!(mem_used),
      swap_free: to_int!(swap_free),
      swap_used: to_int!(swap_used)}
  end

  defp mem_stats("pc") do
    {res, 0} = System.cmd("free", ["-m"])
    [_labels, mem, swap, _buffers] = String.split(res, "\n")
    [_, _mem_total, mem_used, mem_free, _, _, _] = String.split(mem) 
	  [_, _swap_total, swap_used, swap_free] = String.split(swap)
    %{mem_free: to_int!(mem_free),
      mem_used: to_int!(mem_used),
      swap_free: to_int!(swap_free),
      swap_used: to_int!(swap_used)}
  end

  defp to_int!(s) do
    {i, _} = Integer.parse(s)
    i
  end
	
end
