defmodule Marvin.Ev3Mock.Platform do

	@moduledoc "A mock platform"

	@behaviour Marvin.SmartThing.PlatformBehaviour

	alias Marvin.Ev3Mock.{TouchSensor,
												ColorSensor,
												InfraredSensor,
												UltrasonicSensor,
												GyroSensor,
												Tachomotor,
												LED,
												SoundPlayer
											 }
	alias Marvin.SmartThing.Device
	
	### PlatformBehaviour
	
	def mode(_device_type) do
		"mock"
  end
  
  def device_code(device_type) do
    case device_type do
      :infrared -> "mock-ir"
      :touch -> "mock-touch"
      :gyro -> "mock-gyro"
      :color -> "mock-color"
      :ultrasonic -> "mock-us"
      :large -> "mock-l-motor"
      :medium -> "mock-m-motor"
    end
  end

	def device_manager(_type) do
		__MODULE__ # itself for all mock devices
	end

	def sensors() do
		[TouchSensor.new(),
     ColorSensor.new(),
     InfraredSensor.new(),
     UltrasonicSensor.new(),
     GyroSensor.new()]
	end

	def motors() do
		[Tachomotor.new(:large, "outA"),
		 Tachomotor.new(:large, "outB"),
		 Tachomotor.new(:medium, "outC")]
	end

	def sound_players() do
		[SoundPlayer.new()]
	end

	def lights() do
		[LED.new(:green, :left),
		 LED.new(:green, :right),
		 LED.new(:red, :left),
		 LED.new(:red, :right),
		 LED.new(:blue, :left),
		 LED.new(:blue, :right)]
	end

	def shutdown() do
		System.cmd("poweroff", [])
	end

	def id_channel() do
		{channel, _} = Integer.parse(System.get_env("MARVIN_ID_CHANNEL"))
		channel
	end

	def voice() do
		"en-us"
	end

	def sensor_read_sense(%Device{mock: true} = device, sense) do
		apply(device.mod, :read, [device, sense])
	end

	def motor_read_sense(%Device{mock: true} = device, sense) do
		apply(device.mod, :read, [device, sense])
	end

	def sensor_sensitivity(%Device{mock: true} = device, sense) do
		apply(device.mod, :sensitivity, [device, sense])
	end
	
	def motor_sensitivity(%Device{mock: true} = device, sense) do
		apply(device.mod, :sensitivity, [device, sense])
	end

	def actuator_configs() do
		Marvin.Ev3.Actuation.actuator_configs() # Use the Ev3 actuators (acutal actuators are mocked)
	end

	def senses_for_id_channel(channel) do
		[{:beacon_heading, channel}, {:beacon_distance, channel}, {:beacon_on, channel}]
	end

	###

	def execute_command(%Device{mock: true} = device, command, params) do
		apply(device.mod, command, [device | params])
	end


	@doc "Nudge the value of a sense from a mock device"
	def nudge(%Device{mock: true} = device, sense, value, previous_value) do 
	  apply(device.mod, :nudge, [device, sense, value, previous_value])
	end


end
