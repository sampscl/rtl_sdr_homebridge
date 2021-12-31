import Config

config :rtl_sdr_homebridge,
  device_map: %{
    0 => "honeywell_345"
  },
  contact_sensor_map: %{
    49183 => %{
      name: "Deck Door"
    }
  }
