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
    L.locals()
    :ok = RtlSdrHomebridge.DeviceAccumulator.Worker.seen(kind, zone_id)

    state = if zone_state == "closed", do: "1", else: "0"
    tamper = "#{zone_tamper}"
    low_battery = if zone_battery_ok == 1, do: "0", else: "1"
    opts = [qos: 0, timeout: 1_000]

    try do
      with :ok <- Tortoise.publish(RtlSdrHomebridge, "rtl-sdr/#{kind}/#{zone_id}/state", state, opts),
           :ok <- Tortoise.publish(RtlSdrHomebridge, "rtl-sdr/#{kind}/#{zone_id}/tamper", tamper, opts),
           :ok <- Tortoise.publish(RtlSdrHomebridge, "rtl-sdr/#{kind}/#{zone_id}/low_battery", low_battery, opts) do
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
