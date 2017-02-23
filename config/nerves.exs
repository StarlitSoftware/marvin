# Nerves configuration

use Mix.Config

config :nerves, :firmware,
  fwup_conf: "config/fwup.conf",
  rootfs_additions: "config/rootfs-additions"

# if unset, the default regulatory domain is the world domain, "00"
config :nerves_interim_wifi,
regulatory_domain: "US"

config :marvin, # TODO put under :marvin, :ev3
 wifi_driver: "mt7601u"

# Change these options to your  # TODO put under :marvin, :ev3
config :marvin, :wlan0,
  ssid: "cloutiernewman",
  key_mgmt: :"WPA-PSK",
  psk: "peaksisland5725"

