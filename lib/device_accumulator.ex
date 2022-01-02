defmodule RtlSdrHomebridge.DeviceAccumulator.Worker do
  @moduledoc """
  Device accumulator worker. An in-memory cache of all {kind, zone_id} that have been seen.
  """

  use GenServer
  use QolUp.LoggerUtils

  ##############################
  # API
  ##############################

  @spec seen(String.t(), non_neg_integer()) :: :ok
  @doc """
  Mark a device as being seen
  ## Parameters
  - `kind` The kind of zone; e.g. "honeywell_345"
  - `zone_id` The zone id (e.g. 125008)
  ## Returns
  - `:ok` All is well
  """
  def seen(kind, zone_id), do: GenServer.call(__MODULE__, {:seen, kind, zone_id})

  @spec devices() :: %{required({String.t(), non_neg_integer()}) => RtlSdrHomebridge.DeviceAccumulator.Worker.DeviceData.t()}
  @doc """
  Get devices map
  ## Returns
  - `devices` map of {kind, zone_id} => %DeviceData{}
  """
  def devices, do: GenServer.call(__MODULE__, :devices)

  @spec start_link(:ok) :: GenServer.on_start()
  def start_link(:ok), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  defmodule DeviceData do
    @moduledoc false
    @keys ~w/kind zone_id first_seen last_seen/a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{
            kind: String.t(),
            zone_id: non_neg_integer(),
            first_seen: DateTime.t(),
            last_seen: DateTime.t()
          }
  end

  defmodule State do
    @moduledoc false
    @keys ~w/devices/a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{
            devices: %{required({String.t(), non_neg_integer()}) => RtlSdrHomebridge.DeviceAccumulator.Worker.DeviceData.t()}
          }
  end

  ##############################
  # GenServer Callbacks
  ##############################

  @impl GenServer
  def init(:ok) do
    L.info("Starting")
    {:ok, %State{devices: %{}}}
  end

  @impl GenServer
  def handle_call({:seen, kind, zone_id}, _from, state) do
    {:reply, :ok, do_seen(state, kind, zone_id)}
  end

  @impl GenServer
  def handle_call(:devices, _from, state) do
    {:reply, state.devices, state}
  end

  ##############################
  # Internal Calls
  ##############################

  @spec do_seen(State.t(), String.t(), String.t()) :: State.t()
  @doc false
  def do_seen(%State{devices: devices} = state, kind, zone_id) do
    now = DateTime.utc_now()

    %State{
      state
      | devices:
          Map.update(devices, {kind, zone_id}, %DeviceData{kind: kind, zone_id: zone_id, first_seen: now, last_seen: now}, fn value ->
            %DeviceData{value | last_seen: now}
          end)
    }
  end
end
