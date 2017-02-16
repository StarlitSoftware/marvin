# Nerves configuration

use Mix.Config

config :nerves, :firmware,
  fwup_conf: "config/fwup.conf",
  rootfs_additions: "config/rootfs-additions"

# if unset, the default regulatory domain is the world domain, "00"
config :nerves_interim_wifi,
  regulatory_domain: "US"

# Change these options to your
config :nerves, :wlan0,
  ssid: "cloutiernewman",
  key_mgmt: :"WPA-PSK",
  psk: "peaksisland5725"

