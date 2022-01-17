defmodule RtlSdrHomebridge do
  @moduledoc """
  Documentation for `RtlSdrHomebridge`.
  """
  use Application
  use QolUp.LoggerUtils

  def start(_type, _args), do: Supervisor.start_link(children(), strategy: :one_for_one, name: __MODULE__)

  @doc false
  def children do
    mqtt_host = Application.get_env(:rtl_sdr_homebridge, :mqtt_host)
    mqtt_port = Application.get_env(:rtl_sdr_homebridge, :mqtt_port)

    L.info("mqtt_host: #{mqtt_host}, mqtt_port: #{mqtt_port}")

    core_children = [
      Tortoise.Connection.child_spec(
        client_id: RtlSdrHomebridge,
        server: {Tortoise.Transport.Tcp, host: mqtt_host, port: mqtt_port},
        handler: {Tortoise.Handler.Logger, []}
      ),
      RtlSdrHomebridge.DeviceAccumulator.Worker.child_spec(:ok)
    ]

    configured_children =
      :rtl_sdr_homebridge
      |> Application.get_env(:device_map)
      |> Enum.map(fn
        {ndx, "honeywell_345"} ->
          RtlSdrHomebridge.Honeywell345.Worker.child_spec(ndx)
      end)

    core_children ++ configured_children
  end
end
