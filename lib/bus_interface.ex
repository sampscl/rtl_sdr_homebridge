defmodule RtlSdrHomebridge.BusInterface do
  @moduledoc """
  Interface to the messaging bus between the RTL-SDR and Homebridge. Message field transformation happens here.
  """
  use QolUp.LoggerUtils

  @type publish_result :: :ok | {:ok, reference()} | {:error, :unknown_connection} | {:error, :timeout}

  ##############################
  # API
  ##############################

  @spec pub_zone_state(String.t(), non_neg_integer(), String.t(), integer(), integer()) :: publish_result()
  @doc """
  Publish a zone state update
  ## Parameters
  - `kind` The kind of zone; e.g. "honeywell_345"
  - `zone_id` The zone id (e.g. 125008)
  - `zone_state` The zone state (e.g. "closed")
  - `zone_tamper` The zone tamper status (e.g. 1 for tamper, 0 for not tampered)
  - `zone_battery_ok` The battery ok status (e.g. 1 for ok, 0 for battery not ok)
  ## Returns
  - `:ok` All is well
  - `{:error, reason}` Failed for reason
  """
  def pub_zone_state(kind, zone_id, zone_state, zone_tamper, zone_battery_ok) do
    :ok = RtlSdrHomebridge.DeviceAccumulator.Worker.seen(kind, zone_id)

    # The mqttthing plugin does some weird stuff here:
    # state
    #   false = closed
    #   true = open
    # tamper
    #   true = tampered
    #   false = not tampered
    #   but the homebridge logs complain "not an integer" if you send "true" or "false". Yet, if
    #   you send "1" or "0", the accessory state doesn't get updated. So: send true/false to get
    #   the accessory state updated and put up with the logs complaining that the value you
    #   sent wasn't an integer. Except integers are ignored. Sigh.
    # low_battery
    #   true = low battery
    #   false = battery okay
    #   read the comments about tamper; low_battery has the same dumb issue. Sigh.

    state = if zone_state == "closed", do: "false", else: "true"
    tamper = if zone_tamper == 1, do: "true", else: "false"
    low_battery = if zone_battery_ok == 1, do: "false", else: "true"
    opts = [qos: 0, timeout: 1_000]
    base_topic = "rtl-sdr/#{kind}/#{zone_id}"

    L.di(%{tamper: tamper, state: state, low_battery: low_battery, base_topic: base_topic})

    try do
      with :ok <- Tortoise.publish(RtlSdrHomebridge, "#{base_topic}/state", state, opts),
           :ok <- Tortoise.publish(RtlSdrHomebridge, "#{base_topic}/tamper", tamper, opts),
           :ok <- Tortoise.publish(RtlSdrHomebridge, "#{base_topic}/low_battery", low_battery, opts) do
        :ok
      else
        error ->
          L.error("Error publishing: #{inspect(error, pretty: true)}")
          error
      end
    rescue
      error in WithClauseError ->
        case error.term do
          {:error, :timeout} ->
            L.error("Timeout publishing")
            error.term
        end
    end
  end
end
