# Marvin - Implementing communities of smart things

OS variables:

* MARVIN_SYSTEM -- one of pc, ev3 - defaults to pc
* MARVIN_PLATFORM -- one of rover, rover_mock, hub - defaults to rover_mock
* MARVIN_PROFILE -- one of puppy, mommy - defaults to puppy
* MARVIN_COMMUNITY -- defaults to lego
* MARVIN_HOST -- defaults to localhost
* MARVIN_PORT -- defaults to 4000
* MARVIN_PEER -- defaults to ???
* MARVIN_PARENT_URL -- e.g. localhost:4003

To startup MARV in test mode:

MARVIN_SYSTEM=pc MARVIN_PLATFORM=mock_rover MARVIN_PROFILE=puppy MARVIN_ID_CHANNEL=2 MARVIN_PEER=rodney@ukemi MARVIN_PORT=4001 MARVIN_PARENT_URL=localhost:4003 iex --sname marv -S mix phoenix.server


To startup RODNEY

MARVIN_SYSTEM=pc MARVIN_PLATFORM=mock_rover MARVIN_PROFILE=puppy MARVIN_ID_CHANNEL=3 MARVIN_PEER=marv@ukemi MARVIN_PORT=4002 MARVIN_PARENT_URL=localhost:4003 iex --sname rodney -S mix phoenix.server

To startup MOM

MARVIN_SYSTEM=pc MARVIN_PLATFORM=hub MARVIN_PROFILE=mommy MARVIN_COMMUNITY=parents MARVIN_PORT=4003 iex --sname mom -S mix phoenix.server

-----------------

RELEASE

Before release, name the node in rel/vm_args



To start your Nerves app:

  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: http://www.nerves-project.org/
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
