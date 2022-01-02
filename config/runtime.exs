import Config

config :rtl_sdr_homebridge,
  device_map: %{
    0 => "honeywell_345"
  },
  mqtt_host: "192.168.58.150",
  mqtt_port: 1883
