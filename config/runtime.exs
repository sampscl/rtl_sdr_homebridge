import Config

config :rtl_sdr_homebridge,
  device_map: %{
    0 => "honeywell_345"
  },
  contact_sensor_map: %{
    49183 => %{
      name: "Deck Door"
    }
  },
  mqtt_host: "192.168.58.150",
  mqtt_port: 1883
