defmodule Marvin.SmartThing.Application do
	@moduledoc "The smart thing command and control application"
	
  use Application
  require Logger
	alias Marvin.SmartThing.{SmartThingSupervisor, CNS, InternalClock}
	alias Marvin.SmartThing
  import Supervisor.Spec, warn: false

  @poll_runtime_delay 5000

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
		Logger.info("Starting #{__MODULE__}")
#    initialize_nerves() # TODO
		connect_to_nodes()
    children = [
			supervisor(SmartThingSupervisor, [])
#			worker(display(), []) # TODO
    ]
    opts = [strategy: :one_for_one, name: :root_supervisor]
    result = Supervisor.start_link(children, opts)
		SmartThingSupervisor.start_execution()
		SmartThingSupervisor.start_perception()
    Process.spawn(fn -> push_runtime_stats() end, [])
		InternalClock.resume()
		result
  end

  @doc "Return ERTS runtime stats"
  def runtime_stats() do  # In camelCase for Elm's automatic translation
    stats = mem_stats()
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

	def display() do
		Application.get_env(:smart_thing, :display)
	end


  ### Private

	defp connect_to_nodes() do
		SmartThing.nodes()
		|> Enum.each(&(Node.connect(&1)))
		Logger.warn("#{Node.self()} is connected to #{inspect Node.list()}")
	end

  defp mem_stats() do
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

 ### NERVES

	# defp initialize_nerves() do
  #  load_nerves_os_modules()
  #  start_writable_fs()
  #  start_wifi()
	# end

	# defp load_nerves_os_modules() do
	# 	platform_dispatch(:load_nerves_os_modules)
	# end

  # defp start_wifi() do
  #   opts = Application.get_env(:ev3, :wlan0)
  #   Nerves.InterimWiFi.setup "wlan0", opts
	# 	wait_for_ip_address()
  # end

	# defp wait_for_ip_address() do
	# 	case ipaddr() do
	# 		"Unknown" ->
	# 			Logger.warn("Waiting for ip address...")
	# 			Process.sleep(500)
	# 			wait_for_ip_address()
	# 		ip ->
	# 			Logger.warn("Got ip address #{inspect ip}")
	# 			:ok
	# 	end
	# end

  # defp ipaddr() do
  #   case Nerves.NetworkInterface.settings("wlan0") do
  #     {:ok, settings} -> settings.ipv4_address
  #     _ -> "Unknown"
  #   end
  # end

  # defp redirect_logging() do
  #   Logger.add_backend {LoggerFileBackend, :error}
  #   Logger.configure_backend {LoggerFileBackend, :error},
  #     path: "/mnt/system.log",
  #     level: :warn
  # end

  # defp format_appdata() do
  #   case System.cmd("mke2fs", ["-t", "ext4", "-L", "APPDATA", "/dev/mmcblk0p3"]) do
  #     {_, 0} -> :ok
  #     _ -> :error
  #   end
  # end

  # defp maybe_mount_appdata() do
  #   if !File.exists?("/mnt/.initialized") do
  #     # Ignore errors
  #     mount_appdata()
  #     File.write("/mnt/.initialized", "Done!")
  #   end
  #   :ok
  # end

  # defp mount_appdata() do
  #   case System.cmd("mount", ["-t", "ext4", "/dev/mmcblk0p3", "/mnt"]) do
  #     {_, 0} -> :ok
  #     _ -> :error
  #   end
  # end

  # defp start_writable_fs() do
  #   case maybe_mount_appdata() do
  #     :ok ->
  #       redirect_logging()
  #     :error ->
  #       case format_appdata() do
  #         :ok ->
  #           mount_appdata()
  #           redirect_logging()
  #         error -> error
  #       end
  #   end
  # end
	
end
