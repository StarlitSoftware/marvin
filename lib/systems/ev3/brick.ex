defmodule Marvin.Ev3.Brick do

	require Logger

  def start() do
    import Supervisor.Spec
		Logger.info("Starting EV3 system")
    # Initialize
    load_ev3_modules()
    start_writable_fs()
    start_wifi()
    init_alsa()
    # Define workers and child supervisors to be supervised
    children = [
      worker(Marvin.Ev3.Display, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Marvin.Ev3.BrickSupervisor]
    Supervisor.start_link(children, opts)
  end

	def ready?() do
		ipaddr() != "Unknown"
	end

  def ipaddr() do
    case Nerves.NetworkInterface.settings("wlan0") do
      {:ok, settings} -> settings.ipv4_address
      _ -> "Unknown"
    end
  end
 
	### PRIVATE

	defp init_alsa() do
		System.cmd("alsactl", ["restore"])
	end
	
  defp load_ev3_modules() do
		wifi_driver = Application.get_env(:marvin, :wifi_driver)
    System.cmd("modprobe", [wifi_driver])
    System.cmd("/sbin/udevd", ["--daemon"])
    Process.sleep(1000)  # I do not like this line

    System.cmd("modprobe", ["suart_emu"])

    # Port 1 may be disabled -> see rootfs-additions/etc/modprobe.d
    System.cmd("modprobe", ["legoev3_ports"])
    System.cmd("modprobe", ["snd_legoev3"])
    System.cmd("modprobe", ["legoev3_battery"])
    System.cmd("modprobe", ["ev3_uart_sensor_ld"])
  end

  defp start_wifi() do
    opts = Application.get_env(:marvin, :wlan0)
    Nerves.InterimWiFi.setup "wlan0", opts
  end

  defp redirect_logging() do
    Logger.add_backend {LoggerFileBackend, :error}
    Logger.configure_backend {LoggerFileBackend, :error},
      path: "/mnt/system.log",
      level: :info
    Logger.remove_backend :console

    # Turn off kernel logging to the console
    #System.cmd("dmesg", ["-n", "1"])
  end

  defp format_appdata() do
    case System.cmd("mke2fs", ["-t", "ext4", "-L", "APPDATA", "/dev/mmcblk0p3"]) do
      {_, 0} -> :ok
      _ -> :error
    end
  end

  defp maybe_mount_appdata() do
    if !File.exists?("/mnt/.initialized") do
      mount_appdata()
    else
      :ok
    end
  end

  defp mount_appdata() do
    case System.cmd("mount", ["-t", "ext4", "/dev/mmcblk0p3", "/mnt"]) do
      {_, 0} ->
          File.write("/mnt/.initialized", "Done!")
          :ok
      _ ->
          :error
    end
  end

  defp start_writable_fs() do
    case maybe_mount_appdata() do
      :ok ->
        redirect_logging()
      :error ->
        case format_appdata() do
          :ok ->
            mount_appdata()
            redirect_logging()
          error -> error
        end
    end
  end

end
