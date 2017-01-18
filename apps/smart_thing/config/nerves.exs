# Nerves configuration

use Mix.Config

# if unset, the default regulatory domain is the world domain, "00"
config :nerves_interim_wifi,
  regulatory_domain: "US"

# Change these options to your
config :ev3, :wlan0,
  ssid: "cloutiernewman",
  key_mgmt: :"WPA-PSK",
  psk: "peaksisland5725"

config :nerves_io_ethernet, static_config: [
    ip: "192.168.1.120",
    mask: "255.255.0.0",
    router: "192.168.1.1"
    ]
