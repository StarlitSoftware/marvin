# Marvin - Implementing communities of smart things

OS variables:

* MARVIN_PLATFORM -- one of ev3, ev3_mock, hub - defaults to ev3_mock
* MARVIN_PROFILE -- one of puppy, mommy - defaults to puppy
* MARVIN_COMMUNITY -- defaults to lego
* MARVIN_PORT -- defaults to 4000
* MARVIN_PEER -- defaults to ???
* MARVIN_MOTHER -- not supported yet

MARVIN_PLATFORM=mock_ev3 MARVIN_PROFILE=puppy MARVIN_PEER=rodney@ukemi iex MARVIN_PORT=4000 --sname marv -S mix phoenix.server

MARVIN_PLATFORM=mock_ev3 MARVIN_PROFILE=puppy MARVIN_PEER=marv@ukemi iex MARVIN_PORT=4001 --sname rodney -S mix phoenix.server

-----------------

RELEASE

Before release, name the node in rel/vm_args 