defmodule Marvin.Ev3.Platform do

	@behaviour Marvin.SmartThing.PlatformBehaviour

	@moduledoc "Module implementing smart thing platform_dispatch calls"

	alias Marvin.Ev3.{LegoSensor, LegoMotor, LegoSound, LegoLED}
	
	### PlatformBehaviour
	
	def mode(device_type) do
    case device_type do
      :infrared -> "ev3-uart"
      :touch -> "ev3-analog"
      :gyro -> "ev3-uart"
      :color -> "ev3-uart"
      :ultrasonic -> "ev3-uart"
      :large -> "tacho-motor"
      :medium -> "tacho-motor"
    end
  end
  
  def device_code(device_type) do
    case device_type do
      :infrared -> "lego-ev3-ir"
      :touch -> "lego-ev3-touch"
      :gyro -> "lego-ev3-gyro"
      :color -> "lego-ev3-color"
      :ultrasonic -> "lego-ev3-us"
      :large -> "lego-ev3-l-motor"
      :medium -> "lego-ev3-m-motor"
    end
  end

  def load_nerves_os_modules() do
		System.cmd("/sbin/udevd", ["--daemon"])
		Process.sleep(1000)  # I do not like this line
    System.cmd("modprobe", ["suart_emu"])

    # Port 1 may be disabled -> see rootfs-additions/etc/modprobe.d
    System.cmd("modprobe", ["legoev3_ports"])
    System.cmd("modprobe", ["snd_legoev3"])
    System.cmd("modprobe", ["legoev3_battery"])
		System.cmd("modprobe", ["ev3_uart_sensor_ld"])
  end

	def nodes() do
		Application.get_env(:ev3, :nodes)
	end

	def device_manager(type) do
		case type do
			:motor -> LegoMotor
			:sensor -> LegoSensor
			:led -> LegoLED
			:sound -> LegoSound
		end
	end

	def sensors() do
		LegoSensor.sensors()
	end

	def motors() do
		LegoMotor.motors()
	end

	def sound_players() do
		LegoSound.sound_players()
	end

	def lights() do
		LegoLED.leds()
	end

	def shutdown() do
		System.cmd("poweroff", [])
	end

	def thing_channel() do
		Application.get_env(:ev3, :beacon_channel, 0)
	end

	def get_voice() do
		Application.get_env(:ev3, :voice, "en-us")
	end 

	###

end
