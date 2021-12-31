defmodule RtlSdrHomebridge do
  @moduledoc """
  Documentation for `RtlSdrHomebridge`.
  """
  use Application
  use QolUp.LoggerUtils

  def start(_type, _args), do: Supervisor.start_link(children(), strategy: :one_for_one, name: __MODULE__)

  @doc false
  def children do
    core_children = [
      RtlSdrHomebridge.BusInterface.child_spec(:ok)
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
