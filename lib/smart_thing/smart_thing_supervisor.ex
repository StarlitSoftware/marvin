defmodule Marvin.SmartThing.SmartThingSupervisor do

	use Supervisor
	require Logger
	alias Marvin.SmartThing
	alias Marvin.SmartThing.{CNS, Attention, Memory, DetectorsSupervisor, PerceptorsSupervisor, MotivatorsSupervisor, BehaviorsSupervisor, ActuatorsSupervisor, InternalClock, PG2Communicator, RESTCommunicator}

	@name __MODULE__

	### Supervisor Callbacks

	@doc "Start the smart thing supervisor, linking it to its parent supervisor"
  def start_link() do
		Logger.info("Starting #{@name}")
		{:ok, _pid} = Supervisor.start_link(@name, [], [name: @name])
	end 

	@spec init(any) :: {:ok, tuple}
	def init(_) do
		children = [	
		 	worker(CNS, []),
		 	worker(Memory, []),
		 	worker(PG2Communicator, []),
		 	worker(RESTCommunicator, []),
			worker(Attention, []),
			worker(InternalClock, []),
			supervisor(DetectorsSupervisor, []),
		 	supervisor(ActuatorsSupervisor, []),
		 	supervisor(BehaviorsSupervisor, []),
		 	supervisor(MotivatorsSupervisor, []),
		 	supervisor(PerceptorsSupervisor, [])
		]
		opts = [strategy: :one_for_one]
		supervise(children, opts)
	end

	@doc "Start the robot's perception"
	def start_perception() do
		Logger.info("Starting perception")
		start_perceptors()
		start_detectors()
	end

	@doc "Start the robot's execution"
	def start_execution() do
		Logger.info("Starting execution")
 		start_actuators()
		start_behaviors()
		start_motivators()
	end

	### Private

	defp start_detectors() do
		Logger.info("Starting detectors")
		sensing_devices = SmartThing.sensors() ++ SmartThing.motors()
		Enum.each(sensing_devices, &(DetectorsSupervisor.start_detector(&1)))		
	end
	
	defp start_perceptors() do
		Logger.info("Starting perceptors")
		SmartThing.perception_logic() # returns perceptor configs
		|> Enum.each(&(PerceptorsSupervisor.start_perceptor(&1)))
	end

  defp start_motivators() do
		Logger.info("Starting motivators")
		SmartThing.motivation_logic() #returns motivator configs
		|> Enum.each(&(MotivatorsSupervisor.start_motivator(&1)))
	end

  defp start_behaviors() do
		Logger.info("Starting behaviors")
		SmartThing.behavior_logic() # returns behavior configs
		|> Enum.each(&(BehaviorsSupervisor.start_behavior(&1)))
	end

  defp start_actuators() do
		Logger.info("Starting actuators") 
		SmartThing.actuation_logic() # returns actuator configs
		|> Enum.each(&(ActuatorsSupervisor.start_actuator(&1)))
	end
  
end
	
