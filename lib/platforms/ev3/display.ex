defmodule Marvin.Ev3.Display do
	# Authored by Frank Hunleth
	
  use GenServer
  alias ExNcurses, as: N

	@refresh_interval 5000 # Every 2 seconds

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    N.n_begin()
    N.clear()
    N.refresh()
    :timer.send_interval(@refresh_interval, :refresh)
    {:ok, 0}
  end

  def terminate(_reason, _state) do
    N.endwin()
  end

  def handle_info(:refresh, state) do
    N.mvprintw(2, 1, "Hello #{state}")

    N.mvprintw(3, 1, "IP: #{ipaddr()}")
    N.mvprintw(4, 1, "Node: #{node()}")
    N.mvprintw(5, 1, "Battery: #{battery_voltage()}V")
    N.mvprintw(6, 1, "Memory: #{meminfo()}")
    N.refresh()
    {:noreply, state + 1}
  end

  defp ipaddr() do
    case Nerves.NetworkInterface.settings("wlan0") do
      {:ok, settings} -> settings.ipv4_address
      _ -> "Unknown"
    end
  end

  defp battery_voltage() do
    case File.read("/sys/class/power_supply/legoev3-battery/voltage_now") do
      {:ok, microvolts_str} ->
        {microvolts, _} = Integer.parse(microvolts_str)
        Float.round(microvolts / 1000000, 1)
      _ ->
        0
    end
  end

  def meminfo() do
    {free_info, 0} = System.cmd("free", [])
    mem_line = free_info
      |> String.split("\n")  # split into lines
      |> Enum.at(1)          # the "Mem:" line is the second one
      |> String.split(" ")   # split out the fields
      |> Enum.filter(&(&1 != ""))
    {total, _} = Enum.at(mem_line, 1) |> Integer.parse
    {free, _}  = Enum.at(mem_line, 3) |> Integer.parse
    "#{free} KB free / #{total} KB"
  end
end
