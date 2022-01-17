import Config

config :rtl_sdr_homebridge,
  device_map: %{
    # This associates RTL-SDR devices to interpreters. The below example associates the first (index zero) RTL-SDR with the Honeywell 345MHz decoder.
    0 => "honeywell_345"
  },

  # The hostname or IP address of the MQTT broker (you must have MQTT installed)
  mqtt_host: "127.0.0.1",

  # The port number of the MQTT broker; typically this should be left alone at 1883
  mqtt_port: 1883
