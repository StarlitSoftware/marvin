# Marvin - Implementing communities of smart things

OS variables:

* MARVIN_PLATFORM -- one of ev3, ev3_mock, hub - defaults to ev3_mock
* MARVIN_PROFILE -- one of puppy, mommy - defaults to puppy
* MARVIN_COMMUNITY -- defaults to lego
* MARVIN_PORT -- defaults to 4000
* MARVIN_PEER -- defaults to ???
* MARVIN_MOTHER -- not supported yet

MARVIN_PLATFORM=mock_ev3 MARVIN_PROFILE=puppy MARVIN_PEER=rodney@ukemi MARVIN_PORT=4001 MARVIN_PARENT_URL=localhost:4002 iex --sname marv -S mix phoenix.server

MARVIN_PLATFORM=mock_ev3 MARVIN_PROFILE=puppy MARVIN_PEER=marv@ukemi MARVIN_PORT=4002 MARVIN_PARENT_URL=localhost:4001 iex  --sname rodney -S mix phoenix.server

-----------------

RELEASE

Before release, name the node in rel/vm_args 